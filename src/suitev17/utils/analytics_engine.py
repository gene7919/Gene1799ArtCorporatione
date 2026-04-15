#!/usr/bin/env python3
"""
SuiteV17 Analytics - Data Analytics & Visualization Engine
Time-series analysis, reporting, dashboards data
"""
import json
import statistics
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Tuple, Any
from dataclasses import dataclass
from collections import defaultdict
import numpy as np

@dataclass
class MetricSeries:
    name: str
    timestamps: List[str]
    values: List[float]
    labels: Dict[str, str]

class AnalyticsEngine:
    """Engine analytics SuiteV17."""
    
    def __init__(self):
        self.series: Dict[str, MetricSeries] = {}
        self.aggregations: Dict[str, Any] = {}
        
    def add_point(self, metric_name: str, value: float,
                  timestamp: str = None, labels: Dict = None):
        """Aggiunge punto dati."""
        if timestamp is None:
            timestamp = datetime.now().isoformat()
            
        if metric_name not in self.series:
            self.series[metric_name] = MetricSeries(
                name=metric_name,
                timestamps=[],
                values=[],
                labels=labels or {}
            )
            
        series = self.series[metric_name]
        series.timestamps.append(timestamp)
        series.values.append(value)
        
        # Keep last 10000 points
        if len(series.values) > 10000:
            series.values = series.values[-10000:]
            series.timestamps = series.timestamps[-10000:]
            
    def get_series(self, metric_name: str, start: str = None,
                   end: str = None) -> Optional[MetricSeries]:
        """Recupera serie temporale."""
        if metric_name not in self.series:
            return None
            
        series = self.series[metric_name]
        
        if start or end:
            filtered_indices = []
            for i, ts in enumerate(series.timestamps):
                if start and ts < start:
                    continue
                if end and ts > end:
                    continue
                filtered_indices.append(i)
                
            return MetricSeries(
                name=metric_name,
                timestamps=[series.timestamps[i] for i in filtered_indices],
                values=[series.values[i] for i in filtered_indices],
                labels=series.labels
            )
            
        return series
        
    def calculate_stats(self, metric_name: str) -> Dict[str, float]:
        """Calcola statistiche."""
        if metric_name not in self.series:
            return {}
            
        values = self.series[metric_name].values
        
        if not values:
            return {}
            
        return {
            'count': len(values),
            'mean': statistics.mean(values),
            'median': statistics.median(values),
            'stdev': statistics.stdev(values) if len(values) > 1 else 0,
            'min': min(values),
            'max': max(values),
            'p95': np.percentile(values, 95) if len(values) >= 20 else max(values),
            'p99': np.percentile(values, 99) if len(values) >= 100 else max(values)
        }
        
    def moving_average(self, metric_name: str, window: int = 10) -> List[float]:
        """Media mobile."""
        if metric_name not in self.series:
            return []
            
        values = self.series[metric_name].values
        if len(values) < window:
            return []
            
        result = []
        for i in range(window, len(values) + 1):
            avg = sum(values[i-window:i]) / window
            result.append(avg)
            
        return result
        
    def detect_trend(self, metric_name: str) -> Dict:
        """Rileva trend."""
        if metric_name not in self.series:
            return {'trend': 'unknown'}
            
        values = self.series[metric_name].values
        if len(values) < 10:
            return {'trend': 'insufficient_data'}
            
        # Linear regression semplice
        n = len(values)
        x = list(range(n))
        
        x_mean = sum(x) / n
        y_mean = sum(values) / n
        
        numerator = sum((x[i] - x_mean) * (values[i] - y_mean) for i in range(n))
        denominator = sum((x[i] - x_mean) ** 2 for i in range(n))
        
        slope = numerator / denominator if denominator != 0 else 0
        
        # Classifica trend
        if slope > 0.1:
            trend = 'increasing'
        elif slope < -0.1:
            trend = 'decreasing'
        else:
            trend = 'stable'
            
        return {
            'trend': trend,
            'slope': slope,
            'strength': abs(slope)
        }
        
    def aggregate_by_time(self, metric_name: str,
                         interval: str = '1h') -> Dict[str, List]:
        """Aggrega per intervallo temporale."""
        if metric_name not in self.series:
            return {}
            
        series = self.series[metric_name]
        
        # Group by interval
        buckets = defaultdict(list)
        
        for ts, val in zip(series.timestamps, series.values):
            dt = datetime.fromisoformat(ts)
            
            if interval == '1h':
                key = dt.replace(minute=0, second=0, microsecond=0).isoformat()
            elif interval == '1d':
                key = dt.replace(hour=0, minute=0, second=0, microsecond=0).isoformat()
            else:
                key = ts
                
            buckets[key].append(val)
            
        # Calculate aggregations
        result = {
            'timestamps': [],
            'avg': [],
            'min': [],
            'max': [],
            'count': []
        }
        
        for ts in sorted(buckets.keys()):
            values = buckets[ts]
            result['timestamps'].append(ts)
            result['avg'].append(sum(values) / len(values))
            result['min'].append(min(values))
            result['max'].append(max(values))
            result['count'].append(len(values))
            
        return result
        
    def correlate(self, metric1: str, metric2: str) -> float:
        """Calcola correlazione tra due metriche."""
        if metric1 not in self.series or metric2 not in self.series:
            return 0.0
            
        values1 = self.series[metric1].values[-1000:]  # Last 1000
        values2 = self.series[metric2].values[-1000:]
        
        if len(values1) != len(values2) or len(values1) < 2:
            return 0.0
            
        # Pearson correlation
        mean1 = sum(values1) / len(values1)
        mean2 = sum(values2) / len(values2)
        
        numerator = sum((v1 - mean1) * (v2 - mean2) for v1, v2 in zip(values1, values2))
        
        sum_sq1 = sum((v - mean1) ** 2 for v in values1)
        sum_sq2 = sum((v - mean2) ** 2 for v in values2)
        
        denominator = (sum_sq1 * sum_sq2) ** 0.5
        
        return numerator / denominator if denominator != 0 else 0
        
    def generate_report(self, metric_names: List[str]) -> Dict:
        """Genera report analytics."""
        report = {
            'generated_at': datetime.now().isoformat(),
            'metrics': {}
        }
        
        for name in metric_names:
            if name in self.series:
                report['metrics'][name] = {
                    'stats': self.calculate_stats(name),
                    'trend': self.detect_trend(name),
                    'latest': self.series[name].values[-1] if self.series[name].values else None
                }
                
        return report
        
    def forecast_simple(self, metric_name: str, periods: int = 10) -> List[float]:
        """Previsione semplice (trend lineare)."""
        if metric_name not in self.series:
            return []
            
        values = self.series[metric_name].values
        if len(values) < 10:
            return []
            
        trend = self.detect_trend(metric_name)
        slope = trend.get('slope', 0)
        
        last_value = values[-1]
        forecast = []
        
        for i in range(1, periods + 1):
            predicted = last_value + (slope * i)
            forecast.append(predicted)
            
        return forecast
        
    def export_data(self, metric_name: str, format: str = 'json') -> str:
        """Esporta dati."""
        if metric_name not in self.series:
            return ''
            
        series = self.series[metric_name]
        
        data = {
            'name': metric_name,
            'labels': series.labels,
            'data': [
                {'timestamp': ts, 'value': val}
                for ts, val in zip(series.timestamps, series.values)
            ]
        }
        
        if format == 'json':
            return json.dumps(data, indent=2)
        elif format == 'csv':
            lines = ['timestamp,value']
            for ts, val in zip(series.timestamps, series.values):
                lines.append(f'{ts},{val}')
            return '\n'.join(lines)
            
        return ''
        
    def clear_old_data(self, metric_name: str, older_than_days: int = 30):
        """Pulisce dati vecchi."""
        if metric_name not in self.series:
            return
            
        cutoff = datetime.now() - timedelta(days=older_than_days)
        series = self.series[metric_name]
        
        indices_to_keep = [
            i for i, ts in enumerate(series.timestamps)
            if datetime.fromisoformat(ts) > cutoff
        ]
        
        series.timestamps = [series.timestamps[i] for i in indices_to_keep]
        series.values = [series.values[i] for i in indices_to_keep]

def main():
    """Test analytics."""
    engine = AnalyticsEngine()
    
    # Add sample data
    import random
    for i in range(100):
        engine.add_point('cpu_usage', random.uniform(10, 90))
        engine.add_point('memory_usage', random.uniform(40, 80))
        
    print('Stats:', engine.calculate_stats('cpu_usage'))
    print('Trend:', engine.detect_trend('cpu_usage'))
    print('Correlation:', engine.correlate('cpu_usage', 'memory_usage'))

if __name__ == '__main__':
    main()
