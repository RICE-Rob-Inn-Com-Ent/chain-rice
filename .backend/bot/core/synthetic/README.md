# Synthetic Data Pipeline

## Overview

Generate high-quality synthetic data for training, testing, and development without privacy concerns.

## Features

- ✅ **Tabular Data** - Generate structured datasets
- ✅ **Time Series** - Generate temporal data
- ✅ **Text Data** - Generate natural language text
- ✅ **Image Data** - Generate synthetic images
- ✅ **Privacy Preserving** - No real user data exposed
- ✅ **Customizable** - Control distributions and patterns

## Technologies

- **SDV (Synthetic Data Vault)** - Tabular data generation
- **Faker** - Realistic fake data
- **TimeGAN** - Time series synthesis
- **DALL-E / Stable Diffusion** - Image synthesis
- **GPT-based** - Text generation

## Quick Start

### Tabular Data with SDV

```python
from sdv.single_table import GaussianCopulaSynthesizer
from sdv.metadata import SingleTableMetadata
import pandas as pd

# Load real data
real_data = pd.read_csv('customers.csv')

# Create metadata
metadata = SingleTableMetadata()
metadata.detect_from_dataframe(real_data)

# Create synthesizer
synthesizer = GaussianCopulaSynthesizer(metadata)

# Train on real data
synthesizer.fit(real_data)

# Generate synthetic data
synthetic_data = synthesizer.sample(num_rows=1000)

# Validate quality
from sdv.evaluation.single_table import evaluate_quality

quality_report = evaluate_quality(
    real_data,
    synthetic_data,
    metadata
)
```

### Faker for Realistic Data

```python
from faker import Faker
import pandas as pd

fake = Faker()

def generate_user_data(n=1000):
    data = []
    for _ in range(n):
        data.append({
            'id': fake.uuid4(),
            'name': fake.name(),
            'email': fake.email(),
            'address': fake.address(),
            'phone': fake.phone_number(),
            'company': fake.company(),
            'job': fake.job(),
            'credit_card': fake.credit_card_number(),
            'iban': fake.iban(),
            'created_at': fake.date_time_this_year(),
        })
    return pd.DataFrame(data)

users = generate_user_data(1000)
```

### Time Series with TimeGAN

```python
from ydata_synthetic.synthesizers.timeseries import TimeSeriesSynthesizer
from ydata_synthetic.synthesizers import ModelParameters, TrainParameters

# Define model parameters
gan_args = ModelParameters(
    batch_size=128,
    lr=5e-4,
    noise_dim=32,
    layers_dim=128
)

train_args = TrainParameters(
    epochs=1000,
    sequence_length=24,
)

# Create synthesizer
synth = TimeSeriesSynthesizer(
    modelname='timegan',
    model_parameters=gan_args,
    train_args=train_args
)

# Train
synth.fit(real_time_series_data)

# Generate
synthetic_time_series = synth.sample(n_samples=1000)
```

### Text Generation with GPT

```python
from transformers import pipeline

generator = pipeline('text-generation', model='gpt2')

def generate_product_reviews(n=100):
    reviews = []
    prompts = [
        "This product is",
        "I bought this and",
        "My experience with this product",
    ]

    for _ in range(n):
        prompt = random.choice(prompts)
        result = generator(
            prompt,
            max_length=100,
            num_return_sequences=1
        )
        reviews.append(result[0]['generated_text'])

    return reviews
```

## Advanced: Privacy-Preserving Synthesis

### Differential Privacy

```python
from sdv.single_table import CTGANSynthesizer
from sdv.metadata import SingleTableMetadata

# Add differential privacy
synthesizer = CTGANSynthesizer(
    metadata,
    epsilon=1.0,  # Privacy budget
    epochs=300,
    enforce_min_max_values=True,
)

synthesizer.fit(sensitive_data)
synthetic_data = synthesizer.sample(1000)
```

### Conditional Generation

```python
# Generate data with specific conditions
conditions = {
    'age': 25,
    'country': 'USA'
}

synthetic_data = synthesizer.sample_conditional(
    num_rows=1000,
    conditions=conditions
)
```

## Image Synthesis

### Stable Diffusion

```python
from diffusers import StableDiffusionPipeline
import torch

pipe = StableDiffusionPipeline.from_pretrained(
    "stabilityai/stable-diffusion-2-1",
    torch_dtype=torch.float16
)
pipe = pipe.to("cuda")

# Generate images
prompts = [
    "professional headshot photo",
    "product photography on white background",
    "medical scan image",
]

for i, prompt in enumerate(prompts):
    image = pipe(prompt).images[0]
    image.save(f"synthetic_image_{i}.png")
```

## Data Quality Validation

```python
from sdmetrics.reports.single_table import QualityReport

# Generate quality report
report = QualityReport()
report.generate(real_data, synthetic_data, metadata)

# Get score
score = report.get_score()
print(f"Quality Score: {score}")

# Get detailed metrics
properties = report.get_properties()
print(properties)
```

## Use Cases

### 1. Testing & Development

```python
# Generate test data for CI/CD
def create_test_dataset(size='small'):
    sizes = {
        'small': 100,
        'medium': 1000,
        'large': 10000
    }
    return generate_user_data(sizes[size])
```

### 2. Model Training

```python
# Augment training data
real_data = load_training_data()
synth = create_synthesizer(real_data)
synthetic_data = synth.sample(num_rows=len(real_data) * 2)
combined_data = pd.concat([real_data, synthetic_data])
```

### 3. Data Sharing

```python
# Create shareable dataset without privacy concerns
public_dataset = synthesizer.sample(
    num_rows=5000,
    randomize_samples=True
)
public_dataset.to_csv('public_dataset.csv', index=False)
```

## References

- [SDV](https://sdv.dev/)
- [Faker](https://faker.readthedocs.io/)
- [ydata-synthetic](https://github.com/ydataai/ydata-synthetic)
