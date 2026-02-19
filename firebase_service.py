"""
Firebase Service for Smart Farm - Production Ready
Handles Firebase initialization and data synchronization
Supports dual-write architecture with MySQL
"""

import firebase_admin
from firebase_admin import credentials, firestore
import logging
import os
from datetime import datetime
from typing import Dict, List, Optional

logger = logging.getLogger(__name__)


class FirebaseService:
    """
    Firebase service for real-time data synchronization
    Implements non-blocking writes and error handling
    """

    _instance = None

    def __new__(cls):
        """Singleton pattern for Firebase service"""
        if cls._instance is None:
            cls._instance = super(FirebaseService, cls).__new__(cls)
        return cls._instance

    def __init__(self):
        """Initialize Firebase Admin SDK"""
        if hasattr(self, '_initialized'):
            return

        self.db = None
        self._initialized = True
        self._init_firebase()

    def _init_firebase(self):
        """Initialize Firebase connection"""
        try:
            firebase_key_path = os.getenv('FIREBASE_CONFIG_PATH', 'firebase_key.json')

            if not os.path.exists(firebase_key_path):
                logger.warning(f"Firebase key not found at {firebase_key_path}. Firebase sync disabled.")
                self.db = None
                return

            # Initialize Firebase Admin SDK
            if not firebase_admin._apps:
                cred = credentials.Certificate(firebase_key_path)
                firebase_admin.initialize_app(cred)

            self.db = firestore.client()
            logger.info("✅ Firebase initialized successfully")

        except Exception as e:
            logger.error(f"❌ Firebase initialization error: {e}")
            self.db = None

    def is_connected(self) -> bool:
        """Check if Firebase is connected"""
        return self.db is not None

    def save_sensor_data(self, data: Dict) -> bool:
        """
        Save sensor data to Firebase with error handling
        
        Args:
            data: Dictionary containing sensor data
            
        Returns:
            True if successful, False otherwise
        """
        try:
            if not self.db:
                logger.warning("Firebase not connected. Skipping sync.")
                return False

            entry_id = str(data.get("entry_id", ""))
            if not entry_id:
                logger.error("Missing entry_id in sensor data")
                return False

            # Ensure timestamp is present
            if "timestamp" not in data:
                data["timestamp"] = datetime.utcnow().isoformat()

            # Write to Firestore
            doc_ref = self.db.collection("sensor_readings").document(entry_id)
            doc_ref.set(data, merge=True)

            logger.info(f"✅ Saved sensor data to Firebase: entry_id={entry_id}")
            return True

        except Exception as e:
            logger.error(f"❌ Firebase write error: {e}")
            return False

    def save_device_log(self, data: Dict) -> bool:
        """
        Save device control log to Firebase
        
        Args:
            data: Dictionary containing device log
            
        Returns:
            True if successful, False otherwise
        """
        try:
            if not self.db:
                logger.warning("Firebase not connected. Skipping device log.")
                return False

            log_id = str(data.get("log_id", ""))
            if not log_id:
                logger.error("Missing log_id in device log")
                return False

            if "timestamp" not in data:
                data["timestamp"] = datetime.utcnow().isoformat()

            doc_ref = self.db.collection("device_logs").document(log_id)
            doc_ref.set(data, merge=True)

            logger.info(f"✅ Saved device log to Firebase: log_id={log_id}")
            return True

        except Exception as e:
            logger.error(f"❌ Firebase device log error: {e}")
            return False

    def create_alert(self, alert_data: Dict) -> bool:
        """
        Create alert in Firebase when thresholds exceeded
        
        Args:
            alert_data: Dictionary containing alert information
            
        Returns:
            True if successful, False otherwise
        """
        try:
            if not self.db:
                logger.warning("Firebase not connected. Skipping alert.")
                return False

            if "timestamp" not in alert_data:
                alert_data["timestamp"] = datetime.utcnow().isoformat()

            alert_data["created_at"] = datetime.utcnow().isoformat()

            # Add alert to Firebase
            doc_ref = self.db.collection("alerts").add(alert_data)

            logger.warning(f"⚠️  Alert created: {alert_data.get('type')}")
            return True

        except Exception as e:
            logger.error(f"❌ Firebase alert creation error: {e}")
            return False

    def get_latest_sensor_data(self, limit: int = 10) -> List[Dict]:
        """
        Retrieve latest sensor readings from Firebase
        
        Args:
            limit: Number of records to retrieve
            
        Returns:
            List of sensor data dictionaries
        """
        try:
            if not self.db:
                logger.warning("Firebase not connected. Cannot retrieve data.")
                return []

            docs = (
                self.db.collection("sensor_readings")
                .order_by("timestamp", direction=firestore.Query.DESCENDING)
                .limit(limit)
                .stream()
            )

            result = []
            for doc in docs:
                data = doc.to_dict()
                data["id"] = doc.id
                result.append(data)

            logger.info(f"✅ Retrieved {len(result)} sensor readings from Firebase")
            return result

        except Exception as e:
            logger.error(f"❌ Firebase query error: {e}")
            return []

    def get_alerts(self, limit: int = 20) -> List[Dict]:
        """
        Retrieve recent alerts from Firebase
        
        Args:
            limit: Number of alerts to retrieve
            
        Returns:
            List of alert dictionaries
        """
        try:
            if not self.db:
                return []

            docs = (
                self.db.collection("alerts")
                .order_by("created_at", direction=firestore.Query.DESCENDING)
                .limit(limit)
                .stream()
            )

            result = []
            for doc in docs:
                data = doc.to_dict()
                data["id"] = doc.id
                result.append(data)

            return result

        except Exception as e:
            logger.error(f"❌ Firebase alert retrieval error: {e}")
            return []

    def update_device_status(self, device_id: int, status: str) -> bool:
        """
        Update device status in Firebase
        
        Args:
            device_id: Device ID
            status: New status (on/off/auto)
            
        Returns:
            True if successful, False otherwise
        """
        try:
            if not self.db:
                logger.warning("Firebase not connected. Skipping device status update.")
                return False

            doc_ref = self.db.collection("devices").document(str(device_id))
            doc_ref.set({
                "status": status,
                "updated_at": datetime.utcnow().isoformat()
            }, merge=True)

            logger.info(f"✅ Updated device {device_id} status to {status}")
            return True

        except Exception as e:
            logger.error(f"❌ Firebase device status update error: {e}")
            return False

    def delete_document(self, collection: str, doc_id: str) -> bool:
        """
        Delete document from Firebase
        
        Args:
            collection: Collection name
            doc_id: Document ID
            
        Returns:
            True if successful, False otherwise
        """
        try:
            if not self.db:
                return False

            self.db.collection(collection).document(doc_id).delete()
            logger.info(f"✅ Deleted document {doc_id} from {collection}")
            return True

        except Exception as e:
            logger.error(f"❌ Firebase delete error: {e}")
            return False

    def batch_write(self, operations: List[Dict]) -> bool:
        """
        Perform batch write operations for improved performance
        
        Args:
            operations: List of operations (collection, doc_id, data, action)
            
        Returns:
            True if successful, False otherwise
        """
        try:
            if not self.db:
                return False

            batch = self.db.batch()

            for op in operations:
                collection = op.get("collection")
                doc_id = op.get("doc_id")
                data = op.get("data", {})
                action = op.get("action", "set")  # set, update, delete

                if action == "set":
                    batch.set(self.db.collection(collection).document(doc_id), data, merge=True)
                elif action == "update":
                    batch.update(self.db.collection(collection).document(doc_id), data)
                elif action == "delete":
                    batch.delete(self.db.collection(collection).document(doc_id))

            batch.commit()
            logger.info(f"✅ Batch write completed: {len(operations)} operations")
            return True

        except Exception as e:
            logger.error(f"❌ Firebase batch write error: {e}")
            return False


# Global Firebase service instance
firebase_service = FirebaseService()
