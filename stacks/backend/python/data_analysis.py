#!/usr/bin/env python3
"""
📊 Chain Rice Data Analysis - Where Numbers Meet Magic!
This module is all about making data dance! 💃
"""
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
import plotly.express as px
import plotly.graph_objects as go
from plotly.subplots import make_subplots
from rich.console import Console
from rich.panel import Panel
from rich.table import Table
from rich.progress import Progress, SpinnerColumn, TextColumn
import click
from typing import Optional, List, Dict, Any
from sklearn.cluster import KMeans
from sklearn.preprocessing import StandardScaler
from sklearn.decomposition import PCA
import warnings
warnings.filterwarnings('ignore')

console = Console()

class DataAnalyzer:
    """
    The Data Analyzer - Your statistical superhero! 📊
    
    This class is like having a data scientist in your pocket,
    but way cooler because it's Python code!
    """
    
    def __init__(self):
        """Initialize the analyzer with some sick defaults!"""
        self.data: Optional[pd.DataFrame] = None
        self.results: Dict[str, Any] = {}
        
        # Set up plotting style (because we're fancy!)
        plt.style.use('seaborn-v0_8')
        sns.set_palette("husl")
    
    def load_data(self, data: pd.DataFrame) -> 'DataAnalyzer':
        """
        Load data for analysis. This is where the magic begins! ✨
        
        Args:
            data: The DataFrame to analyze
            
        Returns:
            Self for method chaining (because we're cool like that!)
        """
        self.data = data.copy()
        console.print(f"[green]✅ Loaded {len(data)} rows and {len(data.columns)} columns[/green]")
        return self
    
    def basic_stats(self) -> Dict[str, Any]:
        """
        Get basic statistics about the data.
        This is like a health checkup for your data! 🏥
        """
        if self.data is None:
            raise ValueError("No data loaded! Use load_data() first, bruh!")
        
        stats = {
            'shape': self.data.shape,
            'columns': list(self.data.columns),
            'dtypes': self.data.dtypes.to_dict(),
            'missing_values': self.data.isnull().sum().to_dict(),
            'memory_usage': self.data.memory_usage(deep=True).sum(),
            'numeric_summary': self.data.describe().to_dict() if len(self.data.select_dtypes(include=[np.number]).columns) > 0 else {}
        }
        
        self.results['basic_stats'] = stats
        return stats
    
    def visualize_distributions(self, columns: Optional[List[str]] = None, save_path: Optional[str] = None):
        """
        Create beautiful distribution plots! 📈
        
        Args:
            columns: Which columns to plot (default: all numeric)
            save_path: Where to save the plot
        """
        if self.data is None:
            raise ValueError("No data loaded! Use load_data() first, bruh!")
        
        numeric_cols = self.data.select_dtypes(include=[np.number]).columns
        if columns:
            numeric_cols = [col for col in columns if col in numeric_cols]
        
        if len(numeric_cols) == 0:
            console.print("[yellow]⚠️  No numeric columns found for plotting![/yellow]")
            return
        
        # Create subplots
        n_cols = min(3, len(numeric_cols))
        n_rows = (len(numeric_cols) + n_cols - 1) // n_cols
        
        fig, axes = plt.subplots(n_rows, n_cols, figsize=(15, 5 * n_rows))
        if n_rows == 1:
            axes = [axes] if n_cols == 1 else axes
        else:
            axes = axes.flatten()
        
        for i, col in enumerate(numeric_cols):
            if i < len(axes):
                # Histogram
                axes[i].hist(self.data[col].dropna(), bins=30, alpha=0.7, color='skyblue', edgecolor='black')
                axes[i].set_title(f'Distribution of {col}', fontsize=12, fontweight='bold')
                axes[i].set_xlabel(col)
                axes[i].set_ylabel('Frequency')
                axes[i].grid(True, alpha=0.3)
        
        # Hide empty subplots
        for i in range(len(numeric_cols), len(axes)):
            axes[i].set_visible(False)
        
        plt.tight_layout()
        
        if save_path:
            plt.savefig(save_path, dpi=300, bbox_inches='tight')
            console.print(f"[green]✅ Plot saved to {save_path}[/green]")
        
        plt.show()
    
    def correlation_analysis(self, method: str = 'pearson') -> pd.DataFrame:
        """
        Analyze correlations between numeric variables.
        This is like finding the secret relationships in your data! 🔍
        """
        if self.data is None:
            raise ValueError("No data loaded! Use load_data() first, bruh!")
        
        numeric_data = self.data.select_dtypes(include=[np.number])
        if len(numeric_data.columns) < 2:
            console.print("[yellow]⚠️  Need at least 2 numeric columns for correlation![/yellow]")
            return pd.DataFrame()
        
        corr_matrix = numeric_data.corr(method=method)
        self.results['correlation'] = corr_matrix
        
        # Create heatmap
        plt.figure(figsize=(12, 10))
        sns.heatmap(corr_matrix, annot=True, cmap='coolwarm', center=0, 
                   square=True, fmt='.2f', cbar_kws={'shrink': 0.8})
        plt.title(f'Correlation Matrix ({method.title()})', fontsize=16, fontweight='bold')
        plt.tight_layout()
        plt.show()
        
        return corr_matrix
    
    def clustering_analysis(self, n_clusters: int = 3, features: Optional[List[str]] = None):
        """
        Perform clustering analysis using K-Means.
        This groups similar data points together! 🎯
        """
        if self.data is None:
            raise ValueError("No data loaded! Use load_data() first, bruh!")
        
        numeric_data = self.data.select_dtypes(include=[np.number])
        if features:
            numeric_data = numeric_data[features]
        
        if len(numeric_data.columns) < 2:
            console.print("[yellow]⚠️  Need at least 2 numeric columns for clustering![/yellow]")
            return
        
        # Prepare data
        data_clean = numeric_data.dropna()
        scaler = StandardScaler()
        data_scaled = scaler.fit_transform(data_clean)
        
        # Perform clustering
        kmeans = KMeans(n_clusters=n_clusters, random_state=42, n_init=10)
        clusters = kmeans.fit_predict(data_scaled)
        
        # Add clusters to data
        data_with_clusters = data_clean.copy()
        data_with_clusters['cluster'] = clusters
        
        # PCA for visualization
        pca = PCA(n_components=2)
        data_pca = pca.fit_transform(data_scaled)
        
        # Create scatter plot
        plt.figure(figsize=(12, 8))
        scatter = plt.scatter(data_pca[:, 0], data_pca[:, 1], c=clusters, cmap='viridis', alpha=0.7)
        plt.colorbar(scatter)
        plt.title(f'K-Means Clustering (k={n_clusters})', fontsize=16, fontweight='bold')
        plt.xlabel(f'PC1 ({pca.explained_variance_ratio_[0]:.2%} variance)')
        plt.ylabel(f'PC2 ({pca.explained_variance_ratio_[1]:.2%} variance)')
        plt.grid(True, alpha=0.3)
        
        # Add cluster centers
        centers_pca = pca.transform(kmeans.cluster_centers_)
        plt.scatter(centers_pca[:, 0], centers_pca[:, 1], c='red', marker='x', s=200, linewidths=3)
        
        plt.tight_layout()
        plt.show()
        
        # Store results
        self.results['clustering'] = {
            'clusters': clusters,
            'centers': kmeans.cluster_centers_,
            'inertia': kmeans.inertia_,
            'data_with_clusters': data_with_clusters
        }
        
        return data_with_clusters
    
    def time_series_analysis(self, date_col: str, value_col: str, freq: str = 'D'):
        """
        Analyze time series data. This is where trends come alive! 📈
        """
        if self.data is None:
            raise ValueError("No data loaded! Use load_data() first, bruh!")
        
        if date_col not in self.data.columns or value_col not in self.data.columns:
            console.print(f"[red]❌ Columns {date_col} or {value_col} not found![/red]")
            return
        
        # Prepare time series data
        ts_data = self.data[[date_col, value_col]].copy()
        ts_data[date_col] = pd.to_datetime(ts_data[date_col])
        ts_data = ts_data.set_index(date_col).sort_index()
        
        # Resample to specified frequency
        ts_resampled = ts_data.resample(freq).mean()
        
        # Create time series plot
        fig = make_subplots(
            rows=2, cols=1,
            subplot_titles=('Time Series', 'Rolling Average'),
            vertical_spacing=0.1
        )
        
        # Original time series
        fig.add_trace(
            go.Scatter(x=ts_resampled.index, y=ts_resampled[value_col], 
                      name='Original', line=dict(color='blue')),
            row=1, col=1
        )
        
        # Rolling average
        rolling_avg = ts_resampled[value_col].rolling(window=7).mean()
        fig.add_trace(
            go.Scatter(x=rolling_avg.index, y=rolling_avg, 
                      name='7-day Rolling Avg', line=dict(color='red')),
            row=2, col=1
        )
        
        fig.update_layout(
            title=f'Time Series Analysis: {value_col}',
            height=600,
            showlegend=True
        )
        
        fig.show()
        
        # Store results
        self.results['time_series'] = {
            'data': ts_resampled,
            'rolling_avg': rolling_avg,
            'trend': ts_resampled[value_col].diff().mean()
        }
        
        return ts_resampled
    
    def generate_report(self) -> str:
        """
        Generate a comprehensive analysis report.
        This is like a data detective's case file! 🕵️
        """
        if not self.results:
            return "No analysis performed yet! Run some analysis first, bruh!"
        
        report = "# 📊 Chain Rice Data Analysis Report\n\n"
        
        if 'basic_stats' in self.results:
            stats = self.results['basic_stats']
            report += f"## 📋 Basic Statistics\n\n"
            report += f"- **Dataset Shape**: {stats['shape'][0]} rows × {stats['shape'][1]} columns\n"
            report += f"- **Memory Usage**: {stats['memory_usage'] / 1024 / 1024:.2f} MB\n"
            report += f"- **Missing Values**: {sum(stats['missing_values'].values())} total\n\n"
        
        if 'correlation' in self.results:
            corr = self.results['correlation']
            report += f"## 🔗 Correlation Analysis\n\n"
            report += f"- **Strongest Positive Correlation**: {corr.max().max():.3f}\n"
            report += f"- **Strongest Negative Correlation**: {corr.min().min():.3f}\n\n"
        
        if 'clustering' in self.results:
            cluster_info = self.results['clustering']
            report += f"## 🎯 Clustering Analysis\n\n"
            report += f"- **Number of Clusters**: {len(np.unique(cluster_info['clusters']))}\n"
            report += f"- **Inertia**: {cluster_info['inertia']:.2f}\n\n"
        
        if 'time_series' in self.results:
            ts_info = self.results['time_series']
            report += f"## 📈 Time Series Analysis\n\n"
            report += f"- **Trend**: {'Positive' if ts_info['trend'] > 0 else 'Negative'}\n"
            report += f"- **Average Change**: {ts_info['trend']:.3f}\n\n"
        
        report += "---\n*Report generated by Chain Rice Data Analyzer* 🍚"
        
        return report

@click.command()
@click.option('--data-file', '-f', help='CSV file to analyze')
@click.option('--demo', '-d', is_flag=True, help='Run with demo data')
@click.option('--output', '-o', help='Output file for report')
def main(data_file: Optional[str], demo: bool, output: Optional[str]):
    """
    Chain Rice Data Analysis Tool! 📊
    
    This is your one-stop shop for data analysis.
    Perfect for exploring blockchain data, transactions, and more!
    """
    console.print(Panel(
        "[bold blue]📊 Chain Rice Data Analysis Tool[/bold blue]\n"
        "Let's make your data dance! 💃",
        title="Data Analyzer",
        border_style="blue"
    ))
    
    analyzer = DataAnalyzer()
    
    if demo:
        # Generate demo data
        console.print("[yellow]🎲 Generating demo blockchain data...[/yellow]")
        from utils.data_generator import DataGenerator
        generator = DataGenerator()
        data = generator.generate_data('transactions', 1000)
        analyzer.load_data(data)
    elif data_file:
        # Load from file
        console.print(f"[yellow]📁 Loading data from {data_file}...[/yellow]")
        try:
            data = pd.read_csv(data_file)
            analyzer.load_data(data)
        except Exception as e:
            console.print(f"[red]❌ Error loading file: {e}[/red]")
            return
    else:
        console.print("[red]❌ Please specify --data-file or use --demo flag![/red]")
        return
    
    # Run analysis
    with Progress(
        SpinnerColumn(),
        TextColumn("[progress.description]{task.description}"),
        console=console
    ) as progress:
        
        # Basic stats
        task = progress.add_task("Running basic statistics...", total=None)
        stats = analyzer.basic_stats()
        progress.update(task, description="✅ Basic statistics complete")
        
        # Visualizations
        task = progress.add_task("Creating visualizations...", total=None)
        analyzer.visualize_distributions()
        progress.update(task, description="✅ Visualizations complete")
        
        # Correlation analysis
        task = progress.add_task("Analyzing correlations...", total=None)
        analyzer.correlation_analysis()
        progress.update(task, description="✅ Correlation analysis complete")
        
        # Clustering
        task = progress.add_task("Performing clustering...", total=None)
        analyzer.clustering_analysis()
        progress.update(task, description="✅ Clustering complete")
    
    # Generate report
    console.print("[yellow]📝 Generating analysis report...[/yellow]")
    report = analyzer.generate_report()
    
    if output:
        with open(output, 'w') as f:
            f.write(report)
        console.print(f"[green]✅ Report saved to {output}[/green]")
    else:
        console.print(Panel(
            report,
            title="Analysis Report",
            border_style="green"
        ))

if __name__ == "__main__":
    main()
