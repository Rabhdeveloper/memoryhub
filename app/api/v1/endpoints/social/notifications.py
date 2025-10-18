from fastapi import APIRouter, Depends, HTTPException, status, Query
from typing import List, Optional
from datetime import datetime
from bson import ObjectId

from app.schemas.notification import (
    NotificationResponse,
    NotificationListResponse,
    NotificationType
)
from app.models.user import UserInDB
from app.core.security import get_current_user
from app.db.mongodb import get_collection

router = APIRouter()

async def _prepare_notification_response(notif_doc: dict) -> NotificationResponse:
    """Prepare notification document for API response"""
    actor = await get_collection("users").find_one({"_id": notif_doc["actor_id"]})
    
    return NotificationResponse(
        id=str(notif_doc["_id"]),
        type=notif_doc["type"],
        title=notif_doc["title"],
        message=notif_doc["message"],
        target_type=notif_doc.get("target_type"),
        target_id=str(notif_doc["target_id"]) if notif_doc.get("target_id") else None,
        actor_id=str(notif_doc["actor_id"]),
        actor_name=actor.get("full_name") if actor else "Unknown User",
        actor_avatar=actor.get("avatar_url") if actor else None,
        is_read=notif_doc.get("is_read", False),
        created_at=notif_doc["created_at"]
    )

async def create_notification(
    user_id: str,
    notification_type: NotificationType,
    title: str,
    message: str,
    actor_id: str,
    target_type: Optional[str] = None,
    target_id: Optional[str] = None
):
    """Helper function to create a notification"""
    notification_data = {
        "user_id": ObjectId(user_id),
        "type": notification_type,
        "title": title,
        "message": message,
        "actor_id": ObjectId(actor_id),
        "is_read": False,
        "created_at": datetime.utcnow()
    }
    
    if target_type:
        notification_data["target_type"] = target_type
    if target_id:
        notification_data["target_id"] = ObjectId(target_id)
    
    await get_collection("notifications").insert_one(notification_data)

@router.get("/", response_model=NotificationListResponse)
async def list_notifications(
    is_read: Optional[bool] = None,
    notification_type: Optional[NotificationType] = None,
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    current_user: UserInDB = Depends(get_current_user)
):
    """List notifications for current user"""
    query = {"user_id": ObjectId(current_user.id)}
    
    if is_read is not None:
        query["is_read"] = is_read
    if notification_type:
        query["type"] = notification_type
    
    total = await get_collection("notifications").count_documents(query)
    unread_count = await get_collection("notifications").count_documents({
        "user_id": ObjectId(current_user.id),
        "is_read": False
    })
    
    skip = (page - 1) * limit
    pages = (total + limit - 1) // limit
    
    cursor = get_collection("notifications").find(query).sort("created_at", -1).skip(skip).limit(limit)
    
    notifications = []
    async for notif_doc in cursor:
        notifications.append(await _prepare_notification_response(notif_doc))
    
    return NotificationListResponse(
        notifications=notifications,
        total=total,
        unread_count=unread_count,
        page=page,
        pages=pages
    )

@router.put("/{notification_id}/read", status_code=status.HTTP_200_OK)
async def mark_as_read(
    notification_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Mark a notification as read"""
    notif = await get_collection("notifications").find_one({
        "_id": ObjectId(notification_id),
        "user_id": ObjectId(current_user.id)
    })
    
    if not notif:
        raise HTTPException(status_code=404, detail="Notification not found")
    
    await get_collection("notifications").update_one(
        {"_id": ObjectId(notification_id)},
        {"$set": {"is_read": True}}
    )
    
    return {"message": "Notification marked as read"}

@router.put("/read-all", status_code=status.HTTP_200_OK)
async def mark_all_as_read(
    current_user: UserInDB = Depends(get_current_user)
):
    """Mark all notifications as read"""
    result = await get_collection("notifications").update_many(
        {"user_id": ObjectId(current_user.id), "is_read": False},
        {"$set": {"is_read": True}}
    )
    
    return {"message": f"{result.modified_count} notifications marked as read"}

@router.delete("/{notification_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_notification(
    notification_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Delete a notification"""
    result = await get_collection("notifications").delete_one({
        "_id": ObjectId(notification_id),
        "user_id": ObjectId(current_user.id)
    })
    
    if result.deleted_count == 0:
        raise HTTPException(status_code=404, detail="Notification not found")

@router.delete("/", status_code=status.HTTP_200_OK)
async def delete_all_notifications(
    current_user: UserInDB = Depends(get_current_user)
):
    """Delete all notifications for current user"""
    result = await get_collection("notifications").delete_many({
        "user_id": ObjectId(current_user.id)
    })
    
    return {"message": f"{result.deleted_count} notifications deleted"}
