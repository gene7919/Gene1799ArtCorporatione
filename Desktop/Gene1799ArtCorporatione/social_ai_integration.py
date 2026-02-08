"""
Gene1799 Social AI Integrated Framework
Integra automatizzazione social, AI learning e Zora NFT
Sistema completo di bot intelligenti con apprendimento continuo
"""

import asyncio
import json
from datetime import datetime, timedelta
from typing import Dict, List, Any, Optional
from dataclasses import dataclass, asdict

from social_media_automation import (
    SocialMediaManager, SocialPost, TwitterBot, LinkedInBot, TikTokBot, ZoraIntegration
)
from ai_learning_engine import MultiAgentLearningSystem, AGENT_SPECIALIZATIONS


@dataclass
class SocialPost:
    """Post social con tracking per apprendimento"""
    platform: str
    content: str
    hashtags: List[str]
    media_urls: List[str] = None
    scheduled_time: datetime = None
    ai_generated: bool = False
    agent_id: str = None  # Quale agente ha creato
    learning_enabled: bool = True


class SocialAIIntegrationEngine:
    """Motore di integrazione per social media + AI + NFT"""
    
    def __init__(self):
        self.social_manager = SocialMediaManager()
        self.learning_system = MultiAgentLearningSystem()
        self.zora = ZoraIntegration()
        
        self.post_history: List[Dict] = []
        self.engagement_analytics: Dict[str, Any] = {}
        self.nft_moments: List[Dict] = []
        self.ai_insights: List[Dict] = []
    
    async def initialize(self, social_config: Dict[str, Dict[str, str]]):
        """Inizializza il sistema completo"""
        
        print("[*] Initializing Gene1799 Social AI Integration Engine...")
        
        # Inizializza bot social
        await self.social_manager.initialize_bots(social_config)
        
        # Registra agenti nel learning system
        for agent_name, domains in AGENT_SPECIALIZATIONS.items():
            await self.learning_system.register_agent(
                agent_name,
                specialization=", ".join(domains[:2])
            )
        
        # Inizializza Zora
        await self.zora.authenticate()
        
        print("[✓] Sistema inizializzato e pronto")
    
    async def generate_content_with_learning(self, topic: str, style: str = "engaging") -> SocialPost:
        """Genera contenuto usando AI e learning"""
        
        # Chiedi al learning system quale approccio funziona meglio
        best_agent = max(
            self.learning_system.agents.items(),
            key=lambda x: x[1].performance_metrics.avg_result
        )[0]
        
        agent = self.learning_system.agents[best_agent]
        
        # Context per generazione contenuto
        context = {
            "topic": topic,
            "style": style,
            "platform": "all",
            "timestamp": datetime.now().isoformat()
        }
        
        # Chiedi raccomandazioni
        recommendations = await agent.get_recommendations(context)
        
        # Genera contenuto basato su raccomandazioni
        content_templates = {
            "aggressive": f"🚀 {topic} sta rivoluzionando il futuro! #Gene1799 #Future",
            "moderate": f"Scopri come {topic} può trasformare il tuo business 💡 #Innovation",
            "conservative": f"Riflessioni su {topic} e il suo impatto nel 2026 🤔 #Insights"
        }
        
        strategy = recommendations[0]["action"] if recommendations else "moderate"
        content = content_templates.get(strategy, content_templates["moderate"])
        
        post = SocialPost(
            platform="all",
            content=content,
            hashtags=["#Gene1799", "#AI", "#Automation"],
            ai_generated=True,
            agent_id=best_agent,
            learning_enabled=True
        )
        
        return post
    
    async def publish_with_tracking(self, post: SocialPost) -> Dict[str, Any]:
        """Pubblica post e traccia per apprendimento"""
        
        # Pubblica su tutti i platform
        publish_results = await self.social_manager.post_across_platforms(post)
        
        # Crea entry in history con riferimento agente
        history_entry = {
            "timestamp": datetime.now().isoformat(),
            "agent_id": post.agent_id,
            "content": post.content,
            "platforms": list(publish_results.keys()),
            "results": publish_results,
            "learning_enabled": post.learning_enabled
        }
        
        self.post_history.append(history_entry)
        
        return {
            "status": "published",
            "post_id": f"integrated_{int(datetime.now().timestamp())}",
            "platforms": list(publish_results.keys()),
            "results": publish_results
        }
    
    async def track_engagement_and_learn(self):
        """Traccia engagement e fa imparare agli agenti"""
        
        print("[*] Tracking engagement and learning...")
        
        for platform, bot in self.social_manager.bots.items():
            if not bot.engagement_history:
                continue
            
            # Prendi ultimo post da questo bot
            last_post = self.post_history[-1] if self.post_history else None
            if not last_post:
                continue
            
            # Ottieni metriche
            last_metric = bot.engagement_history[-1]
            
            # Calcola score
            total_engagement = (last_metric.likes + last_metric.comments + 
                              last_metric.shares) / 100
            engagement_score = min(total_engagement, 1.0)
            
            # Insegna all'agente
            agent_id = last_post.get("agent_id", "orchestrator")
            if agent_id in self.learning_system.agents:
                agent = self.learning_system.agents[agent_id]
                
                context = {
                    "platform": platform,
                    "engagement_level": engagement_score,
                    "timestamp": datetime.now().isoformat()
                }
                
                # Determina quale strategia è stata usata
                content = last_post.get("content", "")
                strategy = "aggressive" if "🚀" in content else "conservative" if "🤔" in content else "moderate"
                
                await agent.learn_from_action(strategy, engagement_score, context)
                
                print(f"[✓] {agent_id} imparato da {platform}: {engagement_score:.2f}")
    
    async def identify_viral_moments(self) -> List[Dict[str, Any]]:
        """Identifica i momenti virali per creare NFT"""
        
        viral_moments = []
        
        for platform, bot in self.social_manager.bots.items():
            for metric in bot.engagement_history[-10:]:
                # Definisci viral threshold
                viral_threshold = 500  # Views
                
                if metric.views >= viral_threshold:
                    moment = {
                        "platform": platform,
                        "post_id": metric.post_id,
                        "views": metric.views,
                        "engagement": metric.likes + metric.comments + metric.shares,
                        "virality_score": (metric.views / 1000) * (1 + metric.sentiment_score),
                        "timestamp": metric.timestamp.isoformat()
                    }
                    viral_moments.append(moment)
        
        self.nft_moments.extend(viral_moments)
        return viral_moments
    
    async def mint_viral_moments_as_nft(self):
        """Minta automaticamente i momenti virali come NFT su Zora"""
        
        print("[*] Minting viral moments as NFTs...")
        
        for moment in self.nft_moments:
            nft = await self.zora.mint_nft_from_social(
                moment["post_id"],
                moment["platform"]
            )
            
            # Traccia NFT creato
            print(f"[✓] NFT creato: {nft['zora_url']}")
    
    async def distribute_learning_insights(self):
        """Distribuisce insight di apprendimento tra gli agenti"""
        
        print("[*] Distributing learning insights...")
        
        # Identifica agente con migliore performance
        if self.learning_system.agents:
            best_agent_id = max(
                self.learning_system.agents.items(),
                key=lambda x: x[1].performance_metrics.avg_result
            )[0]
            
            best_agent = self.learning_system.agents[best_agent_id]
            patterns = await best_agent.identify_patterns()
            
            # Distribuisci pattern come insight
            for action, score in patterns.get("most_successful_actions", []):
                insight = f"Action '{action}' è efficace con score {score:.2f}"
                
                await self.learning_system.distribute_knowledge(
                    insight=insight,
                    source_agent=best_agent_id,
                    value=score,
                    domains=best_agent.specialization.split(", ")
                )
    
    async def execute_daily_cycle(self):
        """Esegue il ciclo giornaliero completo"""
        
        print("\n" + "="*70)
        print("GENE1799 SOCIAL AI - DAILY CYCLE")
        print("="*70)
        
        # 1. Genera contenuto
        topics = [
            "AI agents per automazione social",
            "Blockchain e intelligenza artificiale",
            "Web3 e il futuro del lavoro",
            "NFT da momenti virali"
        ]
        
        for topic in topics:
            post = await self.generate_content_with_learning(topic)
            result = await self.publish_with_tracking(post)
            print(f"[✓] Published: {result['status']} to {len(result['platforms'])} platforms")
            
            await asyncio.sleep(1)  # Rate limiting
        
        # 2. Traccia engagement
        await self.track_engagement_and_learn()
        
        # 3. Identifica momenti virali
        viral = await self.identify_viral_moments()
        if viral:
            print(f"\n[✓] Identificati {len(viral)} momenti virali")
            await self.mint_viral_moments_as_nft()
        
        # 4. Distribuisci insights
        await self.distribute_learning_insights()
        
        # 5. Genera report
        social_report = await self.social_manager.generate_daily_report()
        learning_report = await self.learning_system.generate_performance_report()
        
        print(social_report)
        print(learning_report)
    
    async def generate_integrated_report(self) -> str:
        """Genera report integrato del sistema completo"""
        
        report = f"""
╔════════════════════════════════════════════════════════════════════╗
║       GENE1799 SOCIAL AI INTEGRATED SYSTEM - COMPLETE REPORT        ║
║                      {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
╚════════════════════════════════════════════════════════════════════╝

SOCIAL MEDIA PERFORMANCE
────────────────────────"""
        
        total_posts = len(self.post_history)
        total_engagement = sum(
            bot.engagement_history[-1].likes + 
            bot.engagement_history[-1].comments +
            bot.engagement_history[-1].shares
            for bot in self.social_manager.bots.values()
            if bot.engagement_history
        )
        
        report += f"""
Total Posts Published: {total_posts}
Total Engagement: {total_engagement}
Platforms Active: {len(self.social_manager.bots)}"""
        
        for platform, bot in self.social_manager.bots.items():
            if bot.engagement_history:
                last_metric = bot.engagement_history[-1]
                report += f"""
  {platform.upper()}: {last_metric.views} views, {last_metric.likes} likes"""
        
        report += f"""

AI LEARNING SYSTEM
──────────────────
Agents Learning: {len(self.learning_system.agents)}
Shared Insights: {len(self.learning_system.shared_knowledge_base)}
Top Performing Agent: """
        
        if self.learning_system.agents:
            top_agent = max(
                self.learning_system.agents.items(),
                key=lambda x: x[1].performance_metrics.avg_result
            )
            report += f"{top_agent[0]} ({top_agent[1].performance_metrics.avg_result:.2f})"
        
        report += f"""

NFT MOMENTS CREATED
───────────────────
Viral Moments Identified: {len(self.nft_moments)}
NFTs Minted: {len(self.nft_moments)}"""
        
        for moment in self.nft_moments[-3:]:
            report += f"""
  • {moment['platform']}: {moment['virality_score']:.2f} virality"""
        
        report += f"""

ZORA.CO INTEGRATION
───────────────────
Network: {self.zora.zora_network}
NFT Collection Created: Gene1799 Social Moments
Auto-Minting: ENABLED for viral posts (1000+ views)

╚════════════════════════════════════════════════════════════════════╝
"""
        return report


# Main entry point
async def main():
    print("\n" + "="*70)
    print("GENE1799 SOCIAL AI INTEGRATION ENGINE")
    print("Social Automation + AI Learning + NFT Creation")
    print("="*70 + "\n")
    
    # Configurazione social media
    social_config = {
        "twitter": {
            "api_key": "YOUR_API_KEY",
            "api_secret": "YOUR_API_SECRET",
            "bearer_token": "YOUR_BEARER_TOKEN"
        },
        "linkedin": {
            "api_key": "YOUR_API_KEY",
            "api_secret": "YOUR_API_SECRET"
        },
        "tiktok": {
            "api_key": "YOUR_API_KEY",
            "api_secret": "YOUR_API_SECRET"
        }
    }
    
    # Inizializza
    engine = SocialAIIntegrationEngine()
    await engine.initialize(social_config)
    
    # Esegui ciclo giornaliero
    await engine.execute_daily_cycle()
    
    # Report finale
    report = await engine.generate_integrated_report()
    print(report)


if __name__ == "__main__":
    asyncio.run(main())
