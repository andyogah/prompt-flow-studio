import React, { useState, useEffect } from 'react';

interface MetricsComparison {
  metric_name: string;
  variant_a: number;
  variant_b: number;
  improvement: number;
  significance: number;
}

interface ABTestResult {
  experiment_id: string;
  status: string;
  metrics_comparison: MetricsComparison[];
}

interface MetricCardProps {
  title: string;
  variantA: number;
  variantB: number;
  unit: string;
  lowerIsBetter?: boolean;
}

const MetricCard: React.FC<MetricCardProps> = ({ 
  title, 
  variantA, 
  variantB, 
  unit, 
  lowerIsBetter = false 
}) => {
  const improvement = ((variantB - variantA) / variantA) * 100;
  const isPositive = lowerIsBetter ? improvement < 0 : improvement > 0;
  
  return (
    <div className="bg-white p-6 rounded-lg shadow-md border">
      <h3 className="text-lg font-semibold text-gray-800 mb-4">{title}</h3>
      
      <div className="grid grid-cols-2 gap-4 mb-4">
        <div className="text-center">
          <div className="text-2xl font-bold text-blue-600">
            {variantA?.toFixed(2)}{unit}
          </div>
          <div className="text-sm text-gray-500">Variant A</div>
        </div>
        
        <div className="text-center">
          <div className="text-2xl font-bold text-green-600">
            {variantB?.toFixed(2)}{unit}
          </div>
          <div className="text-sm text-gray-500">Variant B</div>
        </div>
      </div>
      
      <div className={`text-center p-2 rounded ${
        isPositive ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'
      }`}>
        <span className="font-semibold">
          {isPositive ? '↗' : '↘'} {Math.abs(improvement).toFixed(1)}%
        </span>
        <span className="text-sm ml-2">
          {isPositive ? 'improvement' : 'decline'}
        </span>
      </div>
    </div>
  );
};

const StatisticalSignificance: React.FC<{ 
  pValue: number; 
  winner: string 
}> = ({ pValue, winner }) => {
  const isSignificant = pValue < 0.05;
  
  return (
    <div className={`p-4 rounded-lg ${
      isSignificant ? 'bg-green-100 border-green-300' : 'bg-yellow-100 border-yellow-300'
    } border-2`}>
      <div className="flex items-center justify-between">
        <div>
          <h4 className="font-semibold">Statistical Significance</h4>
          <p className="text-sm">p-value: {pValue.toFixed(4)}</p>
        </div>
        <div className="text-right">
          {isSignificant ? (
            <div className="text-green-600 font-bold">
              ✓ Significant<br/>
              <span className="text-sm">Winner: Variant {winner}</span>
            </div>
          ) : (
            <div className="text-yellow-600 font-bold">
              ⚠ Not Significant<br/>
              <span className="text-sm">Need more data</span>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

const EvaluationDashboard: React.FC<{ experimentId: string }> = ({ experimentId }) => {
  const [experiment, setExperiment] = useState<ABTestResult | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchExperimentData = async () => {
      try {
        const response = await fetch(`/api/v1/evaluation/experiments/${experimentId}/dashboard`);
        const data = await response.json();
        setExperiment(data);
      } catch (error) {
        console.error('Failed to fetch experiment data:', error);
      } finally {
        setLoading(false);
      }
    };

    fetchExperimentData();
    
    // Refresh every 30 seconds
    const interval = setInterval(fetchExperimentData, 30000);
    return () => clearInterval(interval);
  }, [experimentId]);

  if (loading) {
    return <div className="flex justify-center p-8">Loading experiment data...</div>;
  }

  if (!experiment) {
    return <div className="text-center p-8 text-red-600">Failed to load experiment data</div>;
  }

  return (
    <div className="evaluation-dashboard p-6 max-w-7xl mx-auto">
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900 mb-2">A/B Test Results</h1>
        <p className="text-gray-600">Experiment ID: {experiment.experiment_id}</p>
        <div className={`inline-block px-3 py-1 rounded-full text-sm font-medium ${
          experiment.status === 'running' 
            ? 'bg-blue-100 text-blue-800' 
            : 'bg-green-100 text-green-800'
        }`}>
          {experiment.status}
        </div>
      </div>

      {/* Metrics Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 mb-8">
        {experiment.metrics_comparison.map((metric, index) => (
          <MetricCard
            key={index}
            title={metric.metric_name}
            variantA={metric.variant_a}
            variantB={metric.variant_b}
            unit={metric.metric_name.includes('Latency') ? 'ms' : 
                  metric.metric_name.includes('Satisfaction') ? '/5' : ''}
            lowerIsBetter={metric.metric_name.includes('Latency')}
          />
        ))}
      </div>

      {/* Statistical Significance */}
      <StatisticalSignificance 
        pValue={experiment.metrics_comparison[0]?.significance || 1}
        winner="B"  // This would come from the actual results
      />

      {/* Charts and detailed analysis would go here */}
      <div className="mt-8 grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="bg-white p-6 rounded-lg shadow-md">
          <h3 className="text-lg font-semibold mb-4">Performance Trends</h3>
          <div className="h-64 flex items-center justify-center text-gray-500">
            Chart placeholder - integrate with charting library
          </div>
        </div>
        
        <div className="bg-white p-6 rounded-lg shadow-md">
          <h3 className="text-lg font-semibold mb-4">Sample Distribution</h3>
          <div className="h-64 flex items-center justify-center text-gray-500">
            Distribution chart placeholder
          </div>
        </div>
      </div>
    </div>
  );
};

export default EvaluationDashboard;
