"""
LangChain Database Integration for Chain Rice
Provides AI-powered database operations and analysis
"""

import os
import asyncio
import asyncpg
from typing import List, Dict, Any, Optional
from langchain.llms import OpenAI
from langchain.chat_models import ChatOpenAI
from langchain.schema import HumanMessage, SystemMessage
from langchain.agents import create_sql_agent, AgentExecutor
from langchain.sql_database import SQLDatabase
from langchain.tools import Tool
from langchain.prompts import PromptTemplate
from langchain.memory import ConversationBufferMemory
from langchain.chains import SQLDatabaseChain
import json
import logging
from datetime import datetime, timedelta

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class ChainRiceLangChainDB:
    """LangChain-powered database operations for Chain Rice"""
    
    def __init__(self, connection_string: str, openai_api_key: str):
        self.connection_string = connection_string
        self.openai_api_key = openai_api_key
        self.llm = ChatOpenAI(
            model_name="gpt-4",
            temperature=0,
            openai_api_key=openai_api_key
        )
        self.db = None
        self.agent = None
        self.memory = ConversationBufferMemory()
        
    async def initialize(self):
        """Initialize database connection and LangChain agent"""
        try:
            # Create SQLDatabase instance
            self.db = SQLDatabase.from_uri(self.connection_string)
            
            # Create SQL agent
            self.agent = create_sql_agent(
                llm=self.llm,
                db=self.db,
                agent_type="openai-functions",
                verbose=True,
                memory=self.memory
            )
            
            logger.info("LangChain database agent initialized successfully")
            
        except Exception as e:
            logger.error(f"Failed to initialize LangChain database: {e}")
            raise
    
    async def analyze_validator_performance(self) -> Dict[str, Any]:
        """Analyze validator performance using AI"""
        query = """
        Analyze the validator performance data and provide insights on:
        1. Which validators are performing best
        2. Network health metrics
        3. Bitcoin balance distribution
        4. Recommendations for optimization
        """
        
        try:
            result = await self.agent.arun(query)
            return {
                "analysis": result,
                "timestamp": datetime.now().isoformat(),
                "type": "validator_performance"
            }
        except Exception as e:
            logger.error(f"Error analyzing validator performance: {e}")
            return {"error": str(e)}
    
    async def predict_bitcoin_price(self, days: int = 7) -> Dict[str, Any]:
        """Predict Bitcoin price trends using historical data"""
        query = f"""
        Based on historical Bitcoin price data and validator activity patterns,
        provide a price prediction for the next {days} days. Include:
        1. Expected price range
        2. Confidence level
        3. Key factors influencing the prediction
        4. Risk assessment
        """
        
        try:
            result = await self.agent.arun(query)
            return {
                "prediction": result,
                "days": days,
                "timestamp": datetime.now().isoformat(),
                "type": "bitcoin_prediction"
            }
        except Exception as e:
            logger.error(f"Error predicting Bitcoin price: {e}")
            return {"error": str(e)}
    
    async def optimize_validator_strategy(self) -> Dict[str, Any]:
        """Get AI recommendations for validator optimization"""
        query = """
        Analyze the current validator configuration and provide recommendations for:
        1. Optimal stake distribution
        2. Commission rate optimization
        3. Network security improvements
        4. Bitcoin balance management
        5. Risk mitigation strategies
        """
        
        try:
            result = await self.agent.arun(query)
            return {
                "recommendations": result,
                "timestamp": datetime.now().isoformat(),
                "type": "validator_optimization"
            }
        except Exception as e:
            logger.error(f"Error optimizing validator strategy: {e}")
            return {"error": str(e)}
    
    async def generate_network_report(self) -> Dict[str, Any]:
        """Generate comprehensive network report"""
        query = """
        Generate a comprehensive network report including:
        1. Network health summary
        2. Validator performance metrics
        3. Bitcoin balance analysis
        4. Transaction volume trends
        5. Security assessment
        6. Growth projections
        """
        
        try:
            result = await self.agent.arun(query)
            return {
                "report": result,
                "timestamp": datetime.now().isoformat(),
                "type": "network_report"
            }
        except Exception as e:
            logger.error(f"Error generating network report: {e}")
            return {"error": str(e)}
    
    async def query_with_natural_language(self, question: str) -> Dict[str, Any]:
        """Answer natural language questions about the database"""
        try:
            result = await self.agent.arun(question)
            return {
                "answer": result,
                "question": question,
                "timestamp": datetime.now().isoformat(),
                "type": "natural_language_query"
            }
        except Exception as e:
            logger.error(f"Error processing natural language query: {e}")
            return {"error": str(e)}
    
    async def get_validator_insights(self, validator_name: str) -> Dict[str, Any]:
        """Get AI-powered insights for a specific validator"""
        query = f"""
        Provide detailed insights for validator '{validator_name}' including:
        1. Performance analysis
        2. Bitcoin balance trends
        3. Commission optimization suggestions
        4. Risk assessment
        5. Comparison with other validators
        """
        
        try:
            result = await self.agent.arun(query)
            return {
                "validator": validator_name,
                "insights": result,
                "timestamp": datetime.now().isoformat(),
                "type": "validator_insights"
            }
        except Exception as e:
            logger.error(f"Error getting validator insights: {e}")
            return {"error": str(e)}

class BitcoinAnalyzer:
    """Specialized Bitcoin analysis using LangChain"""
    
    def __init__(self, langchain_db: ChainRiceLangChainDB):
        self.db = langchain_db
    
    async def analyze_bitcoin_market(self) -> Dict[str, Any]:
        """Analyze Bitcoin market conditions"""
        query = """
        Analyze Bitcoin market conditions and provide insights on:
        1. Current market sentiment
        2. Price volatility analysis
        3. Trading volume patterns
        4. Correlation with validator activity
        5. Market trend predictions
        """
        
        try:
            result = await self.db.agent.arun(query)
            return {
                "market_analysis": result,
                "timestamp": datetime.now().isoformat(),
                "type": "bitcoin_market_analysis"
            }
        except Exception as e:
            logger.error(f"Error analyzing Bitcoin market: {e}")
            return {"error": str(e)}
    
    async def optimize_bitcoin_holdings(self) -> Dict[str, Any]:
        """Get recommendations for Bitcoin portfolio optimization"""
        query = """
        Based on validator Bitcoin holdings and market conditions, provide:
        1. Optimal Bitcoin allocation strategy
        2. Risk management recommendations
        3. Diversification suggestions
        4. Timing recommendations for transactions
        5. Long-term holding strategy
        """
        
        try:
            result = await self.db.agent.arun(query)
            return {
                "optimization_strategy": result,
                "timestamp": datetime.now().isoformat(),
                "type": "bitcoin_optimization"
            }
        except Exception as e:
            logger.error(f"Error optimizing Bitcoin holdings: {e}")
            return {"error": str(e)}

# Example usage and testing
async def main():
    """Example usage of the LangChain database integration"""
    
    # Configuration
    connection_string = "postgresql://user:password@localhost:5432/chain_rice"
    openai_api_key = os.getenv("OPENAI_API_KEY")
    
    if not openai_api_key:
        logger.error("OPENAI_API_KEY environment variable not set")
        return
    
    # Initialize LangChain database
    langchain_db = ChainRiceLangChainDB(connection_string, openai_api_key)
    await langchain_db.initialize()
    
    # Initialize Bitcoin analyzer
    bitcoin_analyzer = BitcoinAnalyzer(langchain_db)
    
    try:
        # Example queries
        print("=== Validator Performance Analysis ===")
        performance = await langchain_db.analyze_validator_performance()
        print(json.dumps(performance, indent=2))
        
        print("\n=== Bitcoin Price Prediction ===")
        prediction = await langchain_db.predict_bitcoin_price(7)
        print(json.dumps(prediction, indent=2))
        
        print("\n=== Validator Optimization ===")
        optimization = await langchain_db.optimize_validator_strategy()
        print(json.dumps(optimization, indent=2))
        
        print("\n=== Bitcoin Market Analysis ===")
        market_analysis = await bitcoin_analyzer.analyze_bitcoin_market()
        print(json.dumps(market_analysis, indent=2))
        
        print("\n=== Natural Language Query ===")
        nl_query = await langchain_db.query_with_natural_language(
            "Which validator has the highest Bitcoin balance?"
        )
        print(json.dumps(nl_query, indent=2))
        
    except Exception as e:
        logger.error(f"Error in main execution: {e}")

if __name__ == "__main__":
    asyncio.run(main())
