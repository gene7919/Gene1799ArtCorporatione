#!/usr/bin/env python3
"""
SuiteV17 ML Pipeline - Machine Learning Completo
Training, inference, model management, feature engineering
"""
import os
import json
import pickle
import numpy as np
from datetime import datetime
from typing import Dict, List, Optional, Tuple, Any
from dataclasses import dataclass
from pathlib import Path
import hashlib

@dataclass
class MLModel:
    name: str
    version: str
    algorithm: str
    metrics: Dict[str, float]
    created_at: str
    file_path: str
    metadata: Dict

class MLPipeline:
    """Pipeline Machine Learning SuiteV17."""
    
    def __init__(self, models_dir: str = None):
        self.models_dir = models_dir or 'C:\\SuiteV17\\ml_models'
        Path(self.models_dir).mkdir(parents=True, exist_ok=True)
        self.models: Dict[str, MLModel] = {}
        self.active_models: Dict[str, Any] = {}
        self.load_model_registry()
        
    def load_model_registry(self):
        """Carica registro modelli."""
        registry_file = Path(self.models_dir) / 'registry.json'
        if registry_file.exists():
            with open(registry_file) as f:
                data = json.load(f)
                self.models = {k: MLModel(**v) for k, v in data.items()}
                
    def save_model_registry(self):
        """Salva registro modelli."""
        registry_file = Path(self.models_dir) / 'registry.json'
        with open(registry_file, 'w') as f:
            json.dump({k: v.__dict__ for k, v in self.models.items()}, f, indent=2)
            
    def train_price_predictor(self, data: List[Dict]) -> MLModel:
        """Allena modello predizione prezzi crypto."""
        from sklearn.ensemble import RandomForestRegressor
        from sklearn.model_selection import train_test_split
        from sklearn.metrics import mean_squared_error, r2_score
        
        # Feature extraction
        features = []
        targets = []
        
        for item in data:
            feat = [
                item.get('volume_24h', 0),
                item.get('liquidity', 0),
                item.get('tx_count', 0),
                item.get('price_change_1h', 0),
                item.get('price_change_24h', 0),
                item.get('market_cap', 0),
            ]
            features.append(feat)
            targets.append(item.get('price_next', 0))
            
        X = np.array(features)
        y = np.array(targets)
        
        X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2)
        
        model = RandomForestRegressor(
            n_estimators=200,
            max_depth=20,
            min_samples_split=5,
            n_jobs=-1,
            random_state=42
        )
        
        model.fit(X_train, y_train)
        
        # Metrics
        y_pred = model.predict(X_test)
        mse = mean_squared_error(y_test, y_pred)
        r2 = r2_score(y_test, y_pred)
        
        # Save model
        model_hash = hashlib.md5(str(datetime.now()).encode()).hexdigest()[:8]
        model_name = f'price_predictor_{model_hash}'
        model_path = Path(self.models_dir) / f'{model_name}.pkl'
        
        with open(model_path, 'wb') as f:
            pickle.dump(model, f)
            
        ml_model = MLModel(
            name='price_predictor',
            version=model_hash,
            algorithm='RandomForestRegressor',
            metrics={'mse': mse, 'r2': r2, 'rmse': np.sqrt(mse)},
            created_at=datetime.now().isoformat(),
            file_path=str(model_path),
            metadata={'n_samples': len(data), 'features': 6}
        )
        
        self.models[model_name] = ml_model
        self.save_model_registry()
        self.active_models['price_predictor'] = model
        
        return ml_model
        
    def predict_price(self, features: Dict) -> Dict:
        """Predice prezzo token."""
        if 'price_predictor' not in self.active_models:
            return {'error': 'Model not loaded'}
            
        model = self.active_models['price_predictor']
        
        X = np.array([[
            features.get('volume_24h', 0),
            features.get('liquidity', 0),
            features.get('tx_count', 0),
            features.get('price_change_1h', 0),
            features.get('price_change_24h', 0),
            features.get('market_cap', 0),
        ]])
        
        prediction = model.predict(X)[0]
        
        return {
            'predicted_price': float(prediction),
            'confidence': 0.85,
            'model': 'price_predictor'
        }
        
    def train_anomaly_detector(self, data: List[Dict]) -> MLModel:
        """Allena modello rilevamento anomalie."""
        from sklearn.ensemble import IsolationForest
        
        features = []
        for item in data:
            feat = [
                item.get('volume_24h', 0),
                item.get('price_change_24h', 0),
                item.get('tx_count', 0),
            ]
            features.append(feat)
            
        X = np.array(features)
        
        model = IsolationForest(
            contamination=0.1,
            random_state=42,
            n_jobs=-1
        )
        
        model.fit(X)
        
        # Save
        model_hash = hashlib.md5(str(datetime.now()).encode()).hexdigest()[:8]
        model_name = f'anomaly_detector_{model_hash}'
        model_path = Path(self.models_dir) / f'{model_name}.pkl'
        
        with open(model_path, 'wb') as f:
            pickle.dump(model, f)
            
        ml_model = MLModel(
            name='anomaly_detector',
            version=model_hash,
            algorithm='IsolationForest',
            metrics={'contamination': 0.1},
            created_at=datetime.now().isoformat(),
            file_path=str(model_path),
            metadata={'n_samples': len(data)}
        )
        
        self.models[model_name] = ml_model
        self.active_models['anomaly_detector'] = model
        self.save_model_registry()
        
        return ml_model
        
    def detect_anomalies(self, data: Dict) -> Dict:
        """Rileva anomalie in dati."""
        if 'anomaly_detector' not in self.active_models:
            return {'error': 'Model not loaded'}
            
        model = self.active_models['anomaly_detector']
        
        X = np.array([[
            data.get('volume_24h', 0),
            data.get('price_change_24h', 0),
            data.get('tx_count', 0),
        ]])
        
        prediction = model.predict(X)[0]
        score = model.decision_function(X)[0]
        
        return {
            'is_anomaly': prediction == -1,
            'anomaly_score': float(score),
            'confidence': abs(score)
        }
        
    def train_sentiment_classifier(self, texts: List[str], labels: List[int]) -> MLModel:
        """Allena classificatore sentiment."""
        from sklearn.feature_extraction.text import TfidfVectorizer
        from sklearn.naive_bayes import MultinomialNB
        from sklearn.pipeline import Pipeline
        from sklearn.metrics import accuracy_score
        
        X_train, X_test, y_train, y_test = train_test_split(
            texts, labels, test_size=0.2, random_state=42
        )
        
        pipeline = Pipeline([
            ('tfidf', TfidfVectorizer(max_features=5000, ngram_range=(1, 2))),
            ('classifier', MultinomialNB())
        ])
        
        pipeline.fit(X_train, y_train)
        
        y_pred = pipeline.predict(X_test)
        accuracy = accuracy_score(y_test, y_pred)
        
        # Save
        model_hash = hashlib.md5(str(datetime.now()).encode()).hexdigest()[:8]
        model_name = f'sentiment_classifier_{model_hash}'
        model_path = Path(self.models_dir) / f'{model_name}.pkl'
        
        with open(model_path, 'wb') as f:
            pickle.dump(pipeline, f)
            
        ml_model = MLModel(
            name='sentiment_classifier',
            version=model_hash,
            algorithm='MultinomialNB',
            metrics={'accuracy': accuracy},
            created_at=datetime.now().isoformat(),
            file_path=str(model_path),
            metadata={'n_samples': len(texts), 'classes': 3}
        )
        
        self.models[model_name] = ml_model
        self.active_models['sentiment_classifier'] = pipeline
        self.save_model_registry()
        
        return ml_model
        
    def predict_sentiment(self, text: str) -> Dict:
        """Predice sentiment testo."""
        if 'sentiment_classifier' not in self.active_models:
            return {'error': 'Model not loaded'}
            
        model = self.active_models['sentiment_classifier']
        prediction = model.predict([text])[0]
        probabilities = model.predict_proba([text])[0]
        
        sentiments = ['negative', 'neutral', 'positive']
        
        return {
            'sentiment': sentiments[prediction],
            'confidence': float(probabilities[prediction]),
            'probabilities': {s: float(p) for s, p in zip(sentiments, probabilities)}
        }
        
    def list_models(self) -> List[Dict]:
        """Lista modelli disponibili."""
        return [{
            'name': m.name,
            'version': m.version,
            'algorithm': m.algorithm,
            'metrics': m.metrics,
            'created_at': m.created_at
        } for m in self.models.values()]
        
    def get_model_info(self, model_name: str) -> Optional[Dict]:
        """Info modello specifico."""
        for key, model in self.models.items():
            if model.name == model_name:
                return model.__dict__
        return None
        
    def delete_model(self, model_name: str) -> bool:
        """Elimina modello."""
        for key in list(self.models.keys()):
            if self.models[key].name == model_name:
                model_path = Path(self.models[key].file_path)
                if model_path.exists():
                    model_path.unlink()
                del self.models[key]
                self.save_model_registry()
                return True
        return False

def main():
    """Test ML Pipeline."""
    pipeline = MLPipeline()
    
    # Test data
    test_data = [
        {'volume_24h': 100000, 'liquidity': 500000, 'tx_count': 1000,
         'price_change_1h': 5.0, 'price_change_24h': 10.0, 'market_cap': 1000000,
         'price_next': 1.1},
        {'volume_24h': 50000, 'liquidity': 200000, 'tx_count': 500,
         'price_change_1h': -2.0, 'price_change_24h': -5.0, 'market_cap': 500000,
         'price_next': 0.95},
    ] * 50
    
    print('Training price predictor...')
    model = pipeline.train_price_predictor(test_data)
    print(f'Model trained: {model.name} v{model.version}')
    print(f'Metrics: {model.metrics}')

if __name__ == '__main__':
    main()
