#!/usr/bin/env python3
"""
RAG Example with Ollama - Retrieval Augmented Generation
"""

from pathlib import Path

import ollama
from langchain.chains import RetrievalQA
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain_community.embeddings import OllamaEmbeddings
from langchain_community.llms import Ollama
from langchain_community.vectorstores import Chroma


def setup_rag_system(documents_dir: str = "./documents", model: str = "llama3.3", embedding_model: str = "llama3.3"):
    """
    Setup RAG system with local Ollama models

    Args:
        documents_dir: Directory containing text documents
        model: Model for generation
        embedding_model: Model for embeddings
    """

    # Initialize embeddings
    print(f"Initializing embeddings with {embedding_model}...")
    embeddings = OllamaEmbeddings(model=embedding_model, base_url="http://localhost:11434")

    # Load documents
    print(f"Loading documents from {documents_dir}...")
    documents = []
    docs_path = Path(documents_dir)

    if docs_path.exists():
        for file_path in docs_path.glob("*.txt"):
            with open(file_path, "r", encoding="utf-8") as f:
                documents.append(f.read())
    else:
        # Example documents if directory doesn't exist
        documents = [
            """
            Quantum computing uses quantum bits or qubits. Unlike classical bits,
            qubits can exist in superposition, representing both 0 and 1 simultaneously.
            This property enables quantum computers to process vast amounts of data
            in parallel.
            """,
            """
            Machine learning is a subset of artificial intelligence that enables
            systems to learn and improve from experience without being explicitly
            programmed. It focuses on developing algorithms that can access data
            and use it to learn for themselves.
            """,
            """
            Blockchain is a distributed ledger technology that maintains a secure
            and decentralized record of transactions. Each block contains a
            cryptographic hash of the previous block, a timestamp, and transaction data.
            """,
        ]

    # Split documents into chunks
    print("Splitting documents into chunks...")
    text_splitter = RecursiveCharacterTextSplitter(chunk_size=500, chunk_overlap=50)

    splits = []
    for doc in documents:
        splits.extend(text_splitter.split_text(doc))

    # Create vector store
    print("Creating vector store...")
    vectorstore = Chroma.from_texts(texts=splits, embedding=embeddings, persist_directory="./chroma_db")

    # Initialize LLM
    print(f"Initializing LLM with {model}...")
    llm = Ollama(model=model, base_url="http://localhost:11434", temperature=0.7)

    # Create RAG chain
    print("Creating RAG chain...")
    qa_chain = RetrievalQA.from_chain_type(
        llm=llm,
        retriever=vectorstore.as_retriever(search_kwargs={"k": 3}),  # Return top 3 relevant chunks
        return_source_documents=True,
    )

    return qa_chain, vectorstore


def query_rag_system(qa_chain, query: str):
    """Query the RAG system"""

    print(f"\n🔍 Query: {query}")
    print("=" * 80)

    result = qa_chain({"query": query})

    print(f"\n📝 Answer:\n{result['result']}\n")

    if "source_documents" in result:
        print("📚 Source Documents:")
        for i, doc in enumerate(result["source_documents"], 1):
            print(f"\n{i}. {doc.page_content[:200]}...")

    print("=" * 80)


if __name__ == "__main__":
    # Setup RAG system
    qa_chain, vectorstore = setup_rag_system(model="llama3.3", embedding_model="llama3.3")

    # Example queries
    queries = ["What is quantum computing?", "Explain machine learning", "How does blockchain work?"]

    for query in queries:
        query_rag_system(qa_chain, query)
        print()

    # Interactive mode
    print("\n💬 Interactive RAG Chat (type 'exit' to quit)")
    while True:
        user_query = input("\nYour question: ")
        if user_query.lower() in ["exit", "quit"]:
            break
        query_rag_system(qa_chain, user_query)
