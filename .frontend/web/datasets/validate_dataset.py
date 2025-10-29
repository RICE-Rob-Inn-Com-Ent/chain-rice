#!/usr/bin/env python3
"""
Thoth Dataset Validator & Statistics
Waliduje strukturę datasetu i pokazuje szczegółowe statystyki
"""

import json
import sys
from collections import Counter


def load_dataset(filepath):
    """Load and parse JSON dataset"""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            return json.load(f)
    except FileNotFoundError:
        print(f"❌ Plik nie znaleziony: {filepath}")
        sys.exit(1)
    except json.JSONDecodeError as e:
        print(f"❌ Błąd parsowania JSON: {e}")
        sys.exit(1)


def validate_structure(data):
    """Validate dataset structure"""
    errors = []
    warnings = []

    # Check top-level keys
    if 'dataset_info' not in data:
        errors.append("Brak klucza 'dataset_info'")
    if 'training_examples' not in data:
        errors.append("Brak klucza 'training_examples'")
        return errors, warnings

    # Validate examples
    examples = data['training_examples']

    for i, ex in enumerate(examples):
        ex_id = ex.get('id', f'unknown_{i}')

        # Required fields
        if 'id' not in ex:
            errors.append(f"Przykład {i}: brak 'id'")
        if 'task' not in ex:
            errors.append(f"Przykład {ex_id}: brak 'task'")
        if 'conversation' not in ex:
            errors.append(f"Przykład {ex_id}: brak 'conversation'")
            continue

        # Validate conversation
        conv = ex['conversation']
        if not isinstance(conv, list):
            errors.append(f"Przykład {ex_id}: 'conversation' nie jest listą")
            continue

        if len(conv) < 2:
            warnings.append(f"Przykład {ex_id}: konwersacja ma mniej niż 2 wiadomości")

        for j, msg in enumerate(conv):
            if 'role' not in msg:
                errors.append(f"Przykład {ex_id}, msg {j}: brak 'role'")
            elif msg['role'] not in ['user', 'assistant', 'system']:
                warnings.append(f"Przykład {ex_id}, msg {j}: nieznana rola '{msg['role']}'")

            if 'content' not in msg:
                errors.append(f"Przykład {ex_id}, msg {j}: brak 'content'")
            elif not msg['content'].strip():
                warnings.append(f"Przykład {ex_id}, msg {j}: pusta treść")

    return errors, warnings


def compute_statistics(data):
    """Compute dataset statistics"""
    examples = data['training_examples']

    stats = {
        'total_examples': len(examples),
        'tasks': Counter(ex['task'] for ex in examples),
        'avg_conversation_length': 0,
        'min_conversation_length': float('inf'),
        'max_conversation_length': 0,
        'total_tokens': 0,
        'avg_user_prompt_length': 0,
        'avg_assistant_response_length': 0,
    }

    total_conv_len = 0
    user_prompt_lengths = []
    assistant_response_lengths = []

    for ex in examples:
        conv = ex.get('conversation', [])
        conv_len = len(conv)
        total_conv_len += conv_len

        stats['min_conversation_length'] = min(stats['min_conversation_length'], conv_len)
        stats['max_conversation_length'] = max(stats['max_conversation_length'], conv_len)

        for msg in conv:
            content = msg.get('content', '')
            token_count = len(content.split())
            stats['total_tokens'] += token_count

            if msg.get('role') == 'user':
                user_prompt_lengths.append(len(content))
            elif msg.get('role') == 'assistant':
                assistant_response_lengths.append(len(content))

    if examples:
        stats['avg_conversation_length'] = total_conv_len / len(examples)

    if user_prompt_lengths:
        stats['avg_user_prompt_length'] = sum(user_prompt_lengths) / len(user_prompt_lengths)

    if assistant_response_lengths:
        stats['avg_assistant_response_length'] = sum(assistant_response_lengths) / len(assistant_response_lengths)

    return stats


def print_report(data, errors, warnings, stats):
    """Print validation report"""
    print("=" * 70)
    print("📊 THOTH DATASET VALIDATION REPORT")
    print("=" * 70)
    print()

    # Dataset info
    info = data.get('dataset_info', {})
    print("📋 Dataset Info:")
    print(f"   Name: {info.get('name', 'N/A')}")
    print(f"   Version: {info.get('version', 'N/A')}")
    print(f"   Total Examples: {info.get('total_examples', 'N/A')}")
    print()

    # Validation results
    print("🔍 Validation Results:")
    if errors:
        print(f"   ❌ Errors: {len(errors)}")
        for err in errors[:5]:  # Show first 5
            print(f"      - {err}")
        if len(errors) > 5:
            print(f"      ... and {len(errors) - 5} more")
    else:
        print("   ✅ No errors found")

    if warnings:
        print(f"   ⚠️  Warnings: {len(warnings)}")
        for warn in warnings[:5]:
            print(f"      - {warn}")
        if len(warnings) > 5:
            print(f"      ... and {len(warnings) - 5} more")
    else:
        print("   ✅ No warnings")
    print()

    # Statistics
    print("📈 Dataset Statistics:")
    print(f"   Total Examples: {stats['total_examples']}")
    print(f"   Total Tokens: {stats['total_tokens']:,}")
    print(f"   Avg Conversation Length: {stats['avg_conversation_length']:.2f} messages")
    print(f"   Min/Max Conversation: {stats['min_conversation_length']}/{stats['max_conversation_length']} messages")
    print(f"   Avg User Prompt: {stats['avg_user_prompt_length']:.0f} chars")
    print(f"   Avg Assistant Response: {stats['avg_assistant_response_length']:.0f} chars")
    print()

    print("🎯 Task Distribution:")
    for task, count in sorted(stats['tasks'].items(), key=lambda x: -x[1]):
        percentage = (count / stats['total_examples']) * 100
        bar = "█" * int(percentage / 2)
        print(f"   {task:30} {count:4} ({percentage:5.1f}%) {bar}")
    print()

    # Balance check
    task_counts = list(stats['tasks'].values())
    if task_counts:
        min_count = min(task_counts)
        max_count = max(task_counts)
        imbalance = (max_count - min_count) / max_count * 100

        print("⚖️  Balance Check:")
        if imbalance < 10:
            print(f"   ✅ Dobrze zbalansowany (różnica: {imbalance:.1f}%)")
        elif imbalance < 25:
            print(f"   ⚠️  Umiarkowanie zbalansowany (różnica: {imbalance:.1f}%)")
        else:
            print(f"   ❌ Niezbalansowany (różnica: {imbalance:.1f}%)")
        print()

    # Recommendations
    print("💡 Recommendations:")
    if stats['total_examples'] < 1000:
        print("   ⚠️  Dataset ma mniej niż 1000 przykładów - rozważ dodanie więcej")
    else:
        print("   ✅ Wystarczająca liczba przykładów")

    if stats['avg_conversation_length'] < 2:
        print("   ⚠️  Konwersacje są bardzo krótkie - rozważ dodanie więcej kontekstu")

    if imbalance > 20:
        print("   ⚠️  Niezbalansowane klasy - rozważ augmentację mniejszościowych tasków")

    print()
    print("=" * 70)

    # Exit code
    if errors:
        print("❌ Walidacja nie powiodła się")
        return 1
    elif warnings:
        print("⚠️  Walidacja z ostrzeżeniami")
        return 0
    else:
        print("✅ Walidacja zakończona sukcesem")
        return 0


def main():
    if len(sys.argv) < 2:
        print("Usage: python3 validate_dataset.py <dataset.json>")
        print("Example: python3 validate_dataset.py thoth-training-1000.json")
        sys.exit(1)

    filepath = sys.argv[1]

    # Load dataset
    print(f"📂 Ładowanie datasetu: {filepath}")
    data = load_dataset(filepath)

    # Validate
    print("🔍 Walidacja struktury...")
    errors, warnings = validate_structure(data)

    # Compute stats
    print("📊 Obliczanie statystyk...")
    stats = compute_statistics(data)

    # Print report
    exit_code = print_report(data, errors, warnings, stats)
    sys.exit(exit_code)


if __name__ == "__main__":
    main()

