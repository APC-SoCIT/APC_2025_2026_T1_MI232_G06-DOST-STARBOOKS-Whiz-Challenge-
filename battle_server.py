"""
WebSocket Battle Server for Whiz Battle (MongoDB Integration)
Database: starbooksWhizbee
Install: pip install fastapi uvicorn websockets pymongo python-dotenv
Run: python battle_server.py
"""

from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from pymongo import MongoClient
from datetime import datetime
import os
from dotenv import load_dotenv
import json
import asyncio
from typing import Dict
from bson import ObjectId

# Load environment variables
load_dotenv()

app = FastAPI()

# CORS for Flutter
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# MongoDB Connection
MONGO_URI = os.getenv("MONGO_URI", "mongodb://localhost:27017/")
client = MongoClient(MONGO_URI)
db = client['starbooksWhizbee']  # Your existing database

# Collections
battles_collection = db['battle']  # New collection for battles
player_info_collection = db['player_info']  # Your existing collection
game_results_collection = db['game_results']  # New collection for results

# In-memory storage for active connections
active_rooms: Dict[str, dict] = {}
active_connections: Dict[str, WebSocket] = {}

# Helper Functions
def serialize_doc(doc):
    """Convert MongoDB document to JSON-serializable format"""
    if doc and '_id' in doc:
        doc['_id'] = str(doc['_id'])
    return doc

async def broadcast_to_room(room_code: str, message: dict):
    """Send message to all players in a room"""
    print(f"📢 Broadcasting to room {room_code}: {message['event']}")
    
    if room_code in active_rooms:
        room = active_rooms[room_code]
        print(f"📢 Players in room: {room['players']}")
        
        for player_id in room['players']:
            if player_id in active_connections:
                try:
                    await active_connections[player_id].send_json(message)
                    print(f"  ✅ Sent to player {player_id}")
                except Exception as e:
                    print(f"  ❌ Error broadcasting to {player_id}: {e}")
            else:
                print(f"  ⚠️ Player {player_id} not in active connections")
    else:
        print(f"  ⚠️ Room {room_code} not found in active_rooms")

async def save_battle_to_db(room_code: str, room_data: dict):
    """Save battle session to MongoDB"""
    try:
        battle_doc = {
            'room_code': room_code,
            'host_id': room_data['host']['user_id'],
            'host_name': room_data['host']['name'],
            'opponent_id': room_data.get('opponent', {}).get('user_id'),
            'opponent_name': room_data.get('opponent', {}).get('name'),
            'category': room_data['category'],
            'difficulty': room_data['difficulty'],
            'total_questions': room_data['total_questions'],
            'host_score': room_data['scores'].get(room_data['host']['user_id'], 0),
            'opponent_score': room_data['scores'].get(room_data.get('opponent', {}).get('user_id', 'unknown'), 0),
            'status': room_data['status'],
            'created_at': room_data['created_at'],
            'started_at': room_data.get('started_at'),
            'ended_at': datetime.utcnow() if room_data['status'] == 'finished' else None
        }
        
        result = battles_collection.insert_one(battle_doc)
        print(f"✅ Battle saved to MongoDB: {result.inserted_id}")
        return str(result.inserted_id)
    except Exception as e:
        print(f"❌ Error saving battle: {e}")
        return None

async def update_player_stats(user_id: str, won: bool, score: int):
    """Update player statistics in MongoDB"""
    try:
        # Check if user exists
        user = player_info_collection.find_one({'_id': ObjectId(user_id)})
        
        if user:
            # Update existing user stats
            player_info_collection.update_one(
                {'_id': ObjectId(user_id)},
                {
                    '$inc': {
                        'total_battles': 1,
                        'total_wins' if won else 'total_losses': 1,
                        'total_score': score
                    },
                    '$set': {
                        'last_battle': datetime.utcnow()
                    }
                }
            )
            print(f"✅ Updated stats for user {user_id}: {'WIN' if won else 'LOSS'}, Score: {score}")
        else:
            print(f"⚠️ User {user_id} not found in player_info")
    except Exception as e:
        print(f"❌ Error updating stats for {user_id}: {e}")

@app.websocket("/ws/battle/{user_id}")
async def battle_websocket(websocket: WebSocket, user_id: str):
    await websocket.accept()
    active_connections[user_id] = websocket
    print(f"✅ User {user_id} connected")
    
    try:
        # Send connection confirmation
        await websocket.send_json({
            'event': 'connection_open',
            'user_id': user_id
        })
        
        while True:
            data = await websocket.receive_json()
            event = data.get('event')
            print(f"📨 Received event: {event} from {user_id}")
            
            if event == 'create_room':
                # Create new battle room
                room_code = data['room_code']
                
                # Store in MongoDB
                battle_doc = {
                    'room_code': room_code,
                    'host_id': user_id,
                    'host_name': data['host_name'],
                    'category': data['category'],
                    'difficulty': data['difficulty'],
                    'status': 'waiting',
                    'created_at': datetime.utcnow()
                }
                battles_collection.insert_one(battle_doc)
                
                # Store in active rooms
                active_rooms[room_code] = {
                    'host': {
                        'user_id': user_id,
                        'name': data['host_name'],
                        'avatar': data.get('host_avatar', '')
                    },
                    'opponent': None,
                    'category': data['category'],
                    'difficulty': data['difficulty'],
                    'total_questions': data.get('total_questions', 10),
                    'status': 'waiting',
                    'scores': {user_id: 0},
                    'answers_submitted': {user_id: 0},
                    'players': [user_id],
                    'created_at': datetime.utcnow().isoformat()
                }
                
                print(f"🎮 Room created: {room_code}")
                await websocket.send_json({
                    'event': 'room_created',
                    'room_code': room_code,
                    'status': 'waiting'
                })
            
            elif event == 'join_room':
                room_code = data['room_code']
                
                if room_code not in active_rooms:
                    # Check MongoDB for room
                    db_room = battles_collection.find_one({'room_code': room_code, 'status': 'waiting'})
                    if not db_room:
                        await websocket.send_json({
                            'event': 'error',
                            'message': 'Room not found or already started'
                        })
                        continue
                
                room = active_rooms[room_code]
                
                if len(room['players']) >= 2:
                    await websocket.send_json({
                        'event': 'error',
                        'message': 'Room is full'
                    })
                    continue
                
                # Add opponent
                room['opponent'] = {
                    'user_id': user_id,
                    'name': data['player_name'],
                    'avatar': data.get('player_avatar', '')
                }
                room['players'].append(user_id)
                room['scores'][user_id] = 0
                room['answers_submitted'][user_id] = 0
                
                # Update MongoDB
                battles_collection.update_one(
                    {'room_code': room_code},
                    {
                        '$set': {
                            'opponent_id': user_id,
                            'opponent_name': data['player_name'],
                            'status': 'ready'
                        }
                    }
                )
                
                print(f"👥 Player {user_id} joined room {room_code}")
                
                # Notify ALL players in room (including the one who just joined)
                await broadcast_to_room(room_code, {
                    'event': 'player_joined',
                    'player': room['opponent']
                })
            
            elif event == 'start_game':
                room_code = data['room_code']
                if room_code in active_rooms:
                    active_rooms[room_code]['status'] = 'playing'
                    active_rooms[room_code]['started_at'] = datetime.utcnow().isoformat()
                    
                    # Update MongoDB
                    battles_collection.update_one(
                        {'room_code': room_code},
                        {
                            '$set': {
                                'status': 'playing',
                                'started_at': datetime.utcnow()
                            }
                        }
                    )
                    
                    print(f"▶️ Game started in room {room_code}")
                    
                    # FIXED: Changed 'game_started' to 'start_game' to match Flutter
                    await broadcast_to_room(room_code, {
                        'event': 'start_game',  # ✅ FIXED - was 'game_started'
                        'room_code': room_code
                    })
            
            elif event == 'player_answer':
                room_code = data['room_code']
                is_correct = data['is_correct']
                
                if room_code in active_rooms:
                    room = active_rooms[room_code]
                    
                    # Update score
                    if is_correct:
                        room['scores'][user_id] = room['scores'].get(user_id, 0) + 1
                    
                    room['answers_submitted'][user_id] = room['answers_submitted'].get(user_id, 0) + 1
                    
                    print(f"📝 Player {user_id} answered. Score: {room['scores'][user_id]}")
                    
                    # Broadcast score update
                    await broadcast_to_room(room_code, {
                        'event': 'score_update',
                        'player_id': user_id,
                        'score': room['scores'][user_id],
                        'answers_submitted': room['answers_submitted'][user_id]
                    })
                    
                    # Check if game is complete
                    total_questions = room['total_questions']
                    all_finished = all(
                        room['answers_submitted'].get(pid, 0) >= total_questions 
                        for pid in room['players']
                    )
                    
                    if all_finished:
                        room['status'] = 'finished'
                        
                        # Determine winner
                        host_id = room['host']['user_id']
                        opponent_id = room['opponent']['user_id']
                        host_score = room['scores'][host_id]
                        opponent_score = room['scores'][opponent_id]
                        
                        winner_id = host_id if host_score > opponent_score else opponent_id
                        
                        print(f"🏆 Game finished! Winner: {winner_id}")
                        
                        # Save to MongoDB
                        battle_id = await save_battle_to_db(room_code, room)
                        
                        # Update player stats
                        await update_player_stats(host_id, winner_id == host_id, host_score)
                        await update_player_stats(opponent_id, winner_id == opponent_id, opponent_score)
                        
                        # Broadcast game end
                        await broadcast_to_room(room_code, {
                            'event': 'game_end',
                            'winner_id': winner_id,
                            'final_scores': room['scores'],
                            'battle_id': battle_id
                        })
            
            elif event == 'leave_room':
                room_code = data['room_code']
                if room_code in active_rooms:
                    room = active_rooms[room_code]
                    
                    # Update MongoDB
                    battles_collection.update_one(
                        {'room_code': room_code},
                        {'$set': {'status': 'abandoned'}}
                    )
                    
                    await broadcast_to_room(room_code, {
                        'event': 'player_left',
                        'player_id': user_id
                    })
                    
                    # Clean up room if both players left
                    if len(room['players']) <= 1:
                        del active_rooms[room_code]
                        print(f"🗑️ Room {room_code} deleted")
    
    except WebSocketDisconnect:
        print(f"❌ User {user_id} disconnected")
        # Handle disconnection
        if user_id in active_connections:
            del active_connections[user_id]
        
        # Find and update any rooms this player was in
        for room_code, room in list(active_rooms.items()):
            if user_id in room['players']:
                await broadcast_to_room(room_code, {
                    'event': 'player_disconnected',
                    'player_id': user_id
                })
                
                battles_collection.update_one(
                    {'room_code': room_code},
                    {'$set': {'status': 'abandoned'}}
                )
                
                # Remove room if empty
                if len(room['players']) <= 1:
                    del active_rooms[room_code]

# API Endpoints for Laravel Integration

@app.get("/api/battles/active")
async def get_active_battles():
    """Get all active battle rooms"""
    return {
        'active_rooms': len(active_rooms),
        'rooms': [
            {
                'room_code': code,
                'host': room['host']['name'],
                'status': room['status'],
                'players': len(room['players'])
            }
            for code, room in active_rooms.items()
        ]
    }

@app.get("/api/battles/history/{user_id}")
async def get_battle_history(user_id: str, limit: int = 10):
    """Get battle history for a user"""
    try:
        battles = list(battles_collection.find(
            {'$or': [{'host_id': user_id}, {'opponent_id': user_id}]}
        ).sort('created_at', -1).limit(limit))
        
        return {
            'battles': [serialize_doc(battle) for battle in battles]
        }
    except Exception as e:
        return {'error': str(e)}

@app.get("/api/battles/{battle_id}")
async def get_battle_details(battle_id: str):
    """Get specific battle details"""
    try:
        battle = battles_collection.find_one({'_id': ObjectId(battle_id)})
        return serialize_doc(battle) if battle else {'error': 'Battle not found'}
    except Exception as e:
        return {'error': str(e)}

@app.get("/api/users/{user_id}/stats")
async def get_user_stats(user_id: str):
    """Get user battle statistics"""
    try:
        user = player_info_collection.find_one({'_id': ObjectId(user_id)})
        if not user:
            return {'error': 'User not found'}
        
        return {
            'user_id': str(user['_id']),
            'total_battles': user.get('total_battles', 0),
            'total_wins': user.get('total_wins', 0),
            'total_losses': user.get('total_losses', 0),
            'total_score': user.get('total_score', 0),
            'win_rate': round((user.get('total_wins', 0) / max(user.get('total_battles', 1), 1)) * 100, 2)
        }
    except Exception as e:
        return {'error': str(e)}

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    try:
        client.server_info()  # Test MongoDB connection
        return {
            'status': 'ok',
            'active_connections': len(active_connections),
            'active_rooms': len(active_rooms),
            'mongodb': 'connected',
            'database': 'starbooksWhizbee'
        }
    except Exception as e:
        return {
            'status': 'error',
            'mongodb': 'disconnected',
            'error': str(e)
        }

if __name__ == "__main__":
    import uvicorn
    print("=" * 60)
    print("🚀 Starting WebSocket Battle Server with MongoDB...")
    print("=" * 60)
    print(f"📦 MongoDB: {MONGO_URI}")
    print(f"🗄️ Database: starbooksWhizbee")
    print(f"🔌 WebSocket: ws://localhost:8080/ws/battle/{{user_id}}")
    print(f"🌐 API: http://localhost:8080/api/")
    print(f"💚 Health: http://localhost:8080/health")
    print("=" * 60)
    uvicorn.run(app, host="0.0.0.0", port=8080)