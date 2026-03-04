<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>{{ .data.terraform.title }} - Rice Framework</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%);
            color: #333;
            padding: 2rem;
            min-height: 100vh;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background: white;
            border-radius: 12px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            overflow: hidden;
        }
        header {
            background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%);
            color: white;
            padding: 2rem;
            text-align: center;
        }
        h1 { font-size: 2.5rem; margin-bottom: 0.5rem; }
        .subtitle { opacity: 0.9; font-size: 1.1rem; }
        .stats {
            display: flex;
            justify-content: center;
            gap: 2rem;
            margin-top: 1rem;
        }
        .stat {
            text-align: center;
        }
        .stat-value {
            font-size: 2.5rem;
            font-weight: bold;
        }
        .stat-label {
            font-size: 0.9rem;
            opacity: 0.9;
        }
        .content { padding: 2rem; }
        .section {
            margin-bottom: 2rem;
            padding: 1.5rem;
            background: #f8f9fa;
            border-radius: 8px;
            border-left: 4px solid #4facfe;
        }
        .section h2 {
            color: #4facfe;
            margin-bottom: 1rem;
            font-size: 1.5rem;
        }
        .grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
            gap: 1rem;
            margin-top: 1rem;
        }
        .card {
            background: white;
            padding: 1.5rem;
            border-radius: 8px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
            border-top: 3px solid #4facfe;
        }
        .card h3 {
            color: #333;
            margin-bottom: 0.5rem;
            font-size: 1.2rem;
        }
        .status {
            display: inline-block;
            padding: 0.25rem 0.75rem;
            border-radius: 20px;
            font-size: 0.85rem;
            font-weight: 600;
            margin-top: 0.5rem;
        }
        .status.active { background: #d4edda; color: #155724; }
        .status.inactive { background: #f8d7da; color: #721c24; }
        .info {
            color: #666;
            font-size: 0.9rem;
            margin-top: 0.5rem;
        }
        .footer {
            text-align: center;
            padding: 1.5rem;
            background: #f8f9fa;
            color: #666;
            font-size: 0.9rem;
        }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h1>🌱 {{ .data.terraform.title }}</h1>
            <p class="subtitle">Cloud Infrastructure Status</p>
            <div class="stats">
                <div class="stat">
                    <div class="stat-value">{{ .data.terraform.activeResources }}</div>
                    <div class="stat-label">Active Resources</div>
                </div>
            </div>
        </header>
        <div class="content">
            <div class="section">
                <h2>☁️ Cloud Providers</h2>
                <div class="grid">
                    <div class="card">
                        <h3>AWS</h3>
                        <span class="status {{ .data.terraform.clouds.aws.status }}">{{ .data.terraform.clouds.aws.status }}</span>
                        <p class="info">Region: {{ .data.terraform.clouds.aws.region }}</p>
                        <p class="info">Resources: {{ .data.terraform.clouds.aws.resources }}</p>
                    </div>
                    <div class="card">
                        <h3>Azure</h3>
                        <span class="status {{ .data.terraform.clouds.azure.status }}">{{ .data.terraform.clouds.azure.status }}</span>
                        <p class="info">Region: {{ .data.terraform.clouds.azure.region }}</p>
                        <p class="info">Resources: {{ .data.terraform.clouds.azure.resources }}</p>
                    </div>
                    <div class="card">
                        <h3>GCP</h3>
                        <span class="status {{ .data.terraform.clouds.gcp.status }}">{{ .data.terraform.clouds.gcp.status }}</span>
                        <p class="info">Region: {{ .data.terraform.clouds.gcp.region }}</p>
                        <p class="info">Resources: {{ .data.terraform.clouds.gcp.resources }}</p>
                    </div>
                </div>
            </div>
        </div>
        <div class="footer">
            <p>Generated by Rice Framework • Last updated: {{ now | date "2006-01-02 15:04:05" }}</p>
        </div>
    </div>
</body>
</html>
