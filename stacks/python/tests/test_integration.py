#!/usr/bin/env python3
"""
🧪 Chain Rice Integration Tests - The Ultimate Test Suite!
This tests all the connected functionality in our learning toy! 🚀
"""
import pytest
import asyncio
import pandas as pd
import numpy as np
from datetime import datetime, timedelta
from rich.console import Console
from rich.panel import Panel

# Import our modules
from utils.blockchain_simulator import BlockchainSimulator, Transaction, Block
from utils.data_generator import DataGenerator
from utils.ai_helper import AIHelper
from data_analysis import DataAnalyzer
from ai_chat import ChainRiceAI
from cli import cli

console = Console()

class TestChainRiceIntegration:
    """
    Integration tests for the Chain Rice learning toy.
    This is where we test everything working together! 🎯
    """
    
    def test_blockchain_simulation(self):
        """
        Test the blockchain simulator - the heart of our system! ⛓️
        """
        console.print("[yellow]⛓️ Testing blockchain simulation...[/yellow]")
        
        # Create blockchain
        blockchain = BlockchainSimulator(difficulty=2)
        
        # Add some transactions
        blockchain.add_transaction("alice@test.com", "bob@test.com", 10.5)
        blockchain.add_transaction("bob@test.com", "charlie@test.com", 5.0)
        blockchain.add_transaction("charlie@test.com", "alice@test.com", 2.5)
        
        # Mine a block
        block = blockchain.add_block(3)
        
        # Verify blockchain
        assert block is not None
        assert len(blockchain.chain) == 2  # Genesis + mined block
        assert len(block.transactions) == 4  # 3 user + 1 mining reward
        assert blockchain.is_chain_valid()
        
        # Check balances
        alice_balance = blockchain.get_balance("alice@test.com")
        bob_balance = blockchain.get_balance("bob@test.com")
        
        assert alice_balance == 2.5  # -10.5 + 2.5
        assert bob_balance == 5.5  # +10.5 - 5.0
        
        console.print("[green]✅ Blockchain simulation test passed![/green]")
    
    def test_data_generation(self):
        """
        Test the data generator - our data factory! 🏭
        """
        console.print("[yellow]🎲 Testing data generation...[/yellow]")
        
        generator = DataGenerator()
        
        # Generate different types of data
        transactions = generator.generate_transactions(100)
        users = generator.generate_users(50)
        blocks = generator.generate_blocks(20)
        dex_trades = generator.generate_dex_data(200)
        
        # Verify data quality
        assert len(transactions) == 100
        assert len(users) == 50
        assert len(blocks) == 20
        assert len(dex_trades) == 200
        
        # Check required columns
        assert 'amount' in transactions.columns
        assert 'email' in users.columns
        assert 'block_number' in blocks.columns
        assert 'pair' in dex_trades.columns
        
        # Check data types
        assert transactions['amount'].dtype in [np.float64, np.int64]
        assert users['balance'].dtype in [np.float64, np.int64]
        
        console.print("[green]✅ Data generation test passed![/green]")
    
    def test_data_analysis(self):
        """
        Test the data analyzer - our statistical superhero! 📊
        """
        console.print("[yellow]📊 Testing data analysis...[/yellow]")
        
        # Generate sample data
        generator = DataGenerator()
        transactions = generator.generate_transactions(500)
        
        # Analyze data
        analyzer = DataAnalyzer()
        analyzer.load_data(transactions)
        
        # Run analysis
        stats = analyzer.basic_stats()
        corr_matrix = analyzer.correlation_analysis()
        
        # Verify results
        assert stats['shape'][0] == 500
        assert 'correlation' in analyzer.results
        assert corr_matrix is not None
        
        console.print("[green]✅ Data analysis test passed![/green]")
    
    def test_ai_helper(self):
        """
        Test the AI helper - our AI buddy! 🤖
        """
        console.print("[yellow]🤖 Testing AI helper...[/yellow]")
        
        ai_helper = AIHelper()
        
        # Test chat functionality
        response = ai_helper.chat("What is blockchain?")
        assert isinstance(response, str)
        assert len(response) > 0
        
        # Test transaction analysis
        sample_tx = {
            "sender": "0x123...",
            "receiver": "0x456...",
            "amount": 100,
            "token": "RICE"
        }
        analysis = ai_helper.analyze_transaction(sample_tx)
        assert isinstance(analysis, str)
        assert len(analysis) > 0
        
        # Test concept explanation
        explanation = ai_helper.explain_blockchain_concept("smart contract")
        assert isinstance(explanation, str)
        assert len(explanation) > 0
        
        console.print("[green]✅ AI helper test passed![/green]")
    
    def test_end_to_end_workflow(self):
        """
        Test the complete end-to-end workflow - the full monty! 🎆
        """
        console.print("[yellow]🎆 Testing end-to-end workflow...[/yellow]")
        
        # Step 1: Generate data
        generator = DataGenerator()
        transactions = generator.generate_transactions(1000)
        
        # Step 2: Analyze data
        analyzer = DataAnalyzer()
        analyzer.load_data(transactions)
        stats = analyzer.basic_stats()
        
        # Step 3: Simulate blockchain
        blockchain = BlockchainSimulator(difficulty=3)
        blockchain.simulate_transactions(50)
        blockchain.add_block(10)
        
        # Step 4: AI analysis
        ai_helper = AIHelper()
        ai_response = ai_helper.chat("Analyze this blockchain data")
        
        # Step 5: Generate report
        report = analyzer.generate_report()
        
        # Verify everything worked
        assert len(transactions) == 1000
        assert stats['shape'][0] == 1000
        assert len(blockchain.chain) == 2  # Genesis + mined block
        assert isinstance(ai_response, str)
        assert isinstance(report, str)
        assert len(report) > 0
        
        console.print("[green]✅ End-to-end workflow test passed![/green]")
    
    def test_performance_benchmarks(self):
        """
        Test performance benchmarks - because speed matters! ⚡
        """
        console.print("[yellow]⚡ Testing performance benchmarks...[/yellow]")
        
        import time
        
        # Benchmark data generation
        start_time = time.time()
        generator = DataGenerator()
        transactions = generator.generate_transactions(1000)
        generation_time = time.time() - start_time
        
        # Benchmark blockchain simulation
        start_time = time.time()
        blockchain = BlockchainSimulator(difficulty=2)
        blockchain.simulate_transactions(100)
        blockchain.add_block(20)
        simulation_time = time.time() - start_time
        
        # Benchmark data analysis
        start_time = time.time()
        analyzer = DataAnalyzer()
        analyzer.load_data(transactions)
        analyzer.basic_stats()
        analysis_time = time.time() - start_time
        
        # Verify performance (these are generous limits for demo purposes)
        assert generation_time < 5.0  # Should generate 1000 transactions in < 5 seconds
        assert simulation_time < 10.0  # Should simulate blockchain in < 10 seconds
        assert analysis_time < 3.0  # Should analyze data in < 3 seconds
        
        console.print(f"[green]✅ Performance benchmarks passed![/green]")
        console.print(f"  Data generation: {generation_time:.2f}s")
        console.print(f"  Blockchain simulation: {simulation_time:.2f}s")
        console.print(f"  Data analysis: {analysis_time:.2f}s")

def test_cli_functionality():
    """
    Test CLI functionality - our command line interface! 💻
    """
    console.print("[yellow]💻 Testing CLI functionality...[/yellow]")
    
    # Test CLI imports
    from cli import cli, greet, ai, generate_data, simulate_blockchain
    
    # Verify CLI commands exist
    assert callable(cli)
    assert callable(greet)
    assert callable(ai)
    assert callable(generate_data)
    assert callable(simulate_blockchain)
    
    console.print("[green]✅ CLI functionality test passed![/green]")

def test_ai_chat_functionality():
    """
    Test AI chat functionality - our conversational AI! 💬
    """
    console.print("[yellow]💬 Testing AI chat functionality...[/yellow]")
    
    # Test AI chat imports
    from ai_chat import ChainRiceAI, AIHelper
    
    # Create AI instances
    ai_chat = ChainRiceAI()
    ai_helper = AIHelper()
    
    # Test basic functionality
    assert ai_chat is not None
    assert ai_helper is not None
    
    # Test chat response
    response = ai_helper.chat("Hello")
    assert isinstance(response, str)
    assert len(response) > 0
    
    console.print("[green]✅ AI chat functionality test passed![/green]")

def test_data_analysis_functionality():
    """
    Test data analysis functionality - our data science tools! 📈
    """
    console.print("[yellow]📈 Testing data analysis functionality...[/yellow]")
    
    # Test data analysis imports
    from data_analysis import DataAnalyzer
    
    # Create analyzer
    analyzer = DataAnalyzer()
    
    # Generate test data
    generator = DataGenerator()
    data = generator.generate_transactions(100)
    
    # Test analysis
    analyzer.load_data(data)
    stats = analyzer.basic_stats()
    
    # Verify results
    assert stats is not None
    assert 'shape' in stats
    assert stats['shape'][0] == 100
    
    console.print("[green]✅ Data analysis functionality test passed![/green]")

def run_all_tests():
    """
    Run all integration tests - the ultimate test suite! 🧪
    """
    console.print(Panel(
        "[bold blue]🧪 Chain Rice Integration Test Suite[/bold blue]\n"
        "Testing all connected functionality!",
        title="Test Suite",
        border_style="blue"
    ))
    
    # Create test instance
    test_instance = TestChainRiceIntegration()
    
    # Run all tests
    tests = [
        test_instance.test_blockchain_simulation,
        test_instance.test_data_generation,
        test_instance.test_data_analysis,
        test_instance.test_ai_helper,
        test_instance.test_end_to_end_workflow,
        test_instance.test_performance_benchmarks,
        test_cli_functionality,
        test_ai_chat_functionality,
        test_data_analysis_functionality
    ]
    
    passed = 0
    failed = 0
    
    for test in tests:
        try:
            test()
            passed += 1
        except Exception as e:
            console.print(f"[red]❌ Test failed: {test.__name__} - {e}[/red]")
            failed += 1
    
    # Summary
    console.print(Panel(
        f"[bold green]✅ Tests Passed: {passed}[/bold green]\n"
        f"[bold red]❌ Tests Failed: {failed}[/bold red]\n"
        f"[bold blue]📊 Total Tests: {passed + failed}[/bold blue]",
        title="Test Results",
        border_style="green" if failed == 0 else "red"
    ))
    
    return passed, failed

if __name__ == "__main__":
    run_all_tests()
