import { useState } from 'react';
import axios from 'axios';
import { Shield, Zap, AlertTriangle, CheckCircle, Code, Target } from 'lucide-react';

const API_BASE_URL = 'http://localhost:8000';

interface SimulationResult {
  attack_type: string;
  detection_result: {
    anomaly_score: number;
    is_anomalous: boolean;
    threshold: number;
    reconstruction_error: number;
    perplexity: number;
    confidence?: number;
    latency_ms?: number;
  };
  timestamp: string;
}

const AttackSimulation = () => {
  const [selectedAttack, setSelectedAttack] = useState('sql_injection');
  const [targetPath, setTargetPath] = useState('');
  const [isSimulating, setIsSimulating] = useState(false);
  const [results, setResults] = useState<SimulationResult[]>([]);
  const [error, setError] = useState<string | null>(null);

  const attackTypes = [
    {
      id: 'sql_injection',
      name: 'SQL Injection',
      description: 'Classic SQL injection attempt',
      example: "?id=1' OR '1'='1",
      severity: 'critical',
      icon: Code
    },
    {
      id: 'xss',
      name: 'Cross-Site Scripting (XSS)',
      description: 'Malicious script injection',
      example: '?search=<script>alert("XSS")</script>',
      severity: 'high',
      icon: AlertTriangle
    },
    {
      id: 'path_traversal',
      name: 'Path Traversal',
      description: 'Directory traversal attack',
      example: '/../../../etc/passwd',
      severity: 'critical',
      icon: Target
    },
    {
      id: 'command_injection',
      name: 'Command Injection',
      description: 'OS command injection attempt',
      example: 'cmd=ls; cat /etc/passwd',
      severity: 'critical',
      icon: Zap
    }
  ];

  const handleSimulate = async () => {
    // Validate target path
    if (!targetPath.trim()) {
      setError('Please enter a target path (e.g., /api/users, /login, /search)');
      return;
    }

    setIsSimulating(true);
    setError(null);

    try {
      const response = await axios.post(`${API_BASE_URL}/simulate/attack`, {
        attack_type: selectedAttack,
        target_path: targetPath
      });

      setResults(prev => [response.data, ...prev].slice(0, 20));
    } catch (err: any) {
      setError(err.response?.data?.detail || 'Simulation failed');
    } finally {
      setIsSimulating(false);
    }
  };

  const selectedAttackInfo = attackTypes.find(a => a.id === selectedAttack);

  const getSeverityColor = (severity: string) => {
    switch (severity) {
      case 'critical':
        return 'bg-red-100 text-red-800 border-red-300';
      case 'high':
        return 'bg-orange-100 text-orange-800 border-orange-300';
      default:
        return 'bg-yellow-100 text-yellow-800 border-yellow-300';
    }
  };

  const getScoreColor = (score: number) => {
    if (score >= 0.85) return 'text-red-600';
    if (score >= 0.6) return 'text-orange-600';
    if (score >= 0.3) return 'text-yellow-600';
    return 'text-green-600';
  };

  return (
    <div className="p-6 max-w-7xl mx-auto space-y-6">
      {/* Header */}
      <div>
        <h1 className="text-3xl font-bold text-gray-900">Attack Simulation (Synthetic Testing)</h1>
        <p className="text-gray-600 mt-2">
          Test the WAF's detection capabilities with synthetic attacks - No real network requests are made
        </p>
      </div>

      {/* Warning Banner */}
      <div className="bg-amber-50 border-l-4 border-amber-400 p-4 rounded-lg">
        <div className="flex items-start gap-3">
          <AlertTriangle className="w-5 h-5 text-amber-600 flex-shrink-0 mt-0.5" />
          <div>
            <h3 className="text-sm font-semibold text-amber-900">Synthetic Testing Mode</h3>
            <p className="text-sm text-amber-700 mt-1">
              This simulation runs entirely within the application. It generates synthetic attack payloads 
              and tests them through the ML model without making any real network requests or affecting external systems.
            </p>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Configuration Panel */}
        <div className="space-y-6">
          {/* Attack Type Selection */}
          <div className="card">
            <h2 className="text-xl font-bold text-gray-900 mb-4 flex items-center gap-2">
              <Shield className="w-5 h-5" />
              Select Attack Type
            </h2>
            <div className="space-y-3">
              {attackTypes.map(attack => {
                const Icon = attack.icon;
                return (
                  <button
                    key={attack.id}
                    onClick={() => setSelectedAttack(attack.id)}
                    className={`w-full text-left p-4 rounded-lg border-2 transition-all ${
                      selectedAttack === attack.id
                        ? 'border-blue-500 bg-blue-50'
                        : 'border-gray-200 hover:border-gray-300'
                    }`}
                  >
                    <div className="flex items-start gap-3">
                      <Icon className={`w-5 h-5 mt-1 ${
                        selectedAttack === attack.id ? 'text-blue-600' : 'text-gray-400'
                      }`} />
                      <div className="flex-1">
                        <div className="flex items-center gap-2">
                          <span className="font-semibold text-gray-900">{attack.name}</span>
                          <span className={`px-2 py-0.5 rounded text-xs font-semibold ${getSeverityColor(attack.severity)}`}>
                            {attack.severity}
                          </span>
                        </div>
                        <p className="text-sm text-gray-600 mt-1">{attack.description}</p>
                        <code className="text-xs text-gray-500 mt-2 block bg-gray-100 px-2 py-1 rounded">
                          {attack.example}
                        </code>
                      </div>
                    </div>
                  </button>
                );
              })}
            </div>
          </div>

          {/* Target Configuration */}
          <div className="card">
            <h2 className="text-xl font-bold text-gray-900 mb-4">Target Configuration</h2>
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Target Path <span className="text-red-500">*</span>
                </label>
                <input
                  type="text"
                  value={targetPath}
                  onChange={(e) => setTargetPath(e.target.value)}
                  className={`w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 ${
                    !targetPath.trim() ? 'border-gray-300' : 'border-blue-300'
                  }`}
                  placeholder="/api/users"
                />
                <p className="text-xs text-gray-500 mt-1">
                  Enter the API endpoint or path to test (e.g., /api/users, /login, /search)
                </p>
              </div>

              <button
                onClick={handleSimulate}
                disabled={isSimulating || !targetPath.trim()}
                className={`w-full flex items-center justify-center gap-2 ${
                  !targetPath.trim() 
                    ? 'bg-gray-300 text-gray-500 cursor-not-allowed' 
                    : 'btn-primary'
                }`}
              >
                <Zap className="w-4 h-4" />
                {isSimulating ? 'Simulating...' : 'Run Simulation'}
              </button>

              {error && (
                <div className="p-4 bg-red-50 border border-red-200 rounded-lg">
                  <p className="text-sm text-red-600">{error}</p>
                </div>
              )}
            </div>
          </div>
        </div>

        {/* Results Panel */}
        <div className="card">
          <h2 className="text-xl font-bold text-gray-900 mb-4">Simulation Results</h2>
          
          {results.length === 0 ? (
            <div className="text-center py-12 text-gray-500">
              <Shield className="w-12 h-12 text-gray-400 mx-auto mb-3" />
              <p className="font-medium">No simulations run yet</p>
              <p className="text-sm mt-1">Select an attack type and run a synthetic test</p>
            </div>
          ) : (
            <div className="space-y-4 max-h-[600px] overflow-y-auto">
              {results.map((result, idx) => (
                <div
                  key={idx}
                  className={`p-4 rounded-lg border-2 transition-all duration-300 hover:shadow-md ${
                    result.detection_result.is_anomalous
                      ? 'bg-green-50 border-green-300'
                      : 'bg-red-50 border-red-300'
                  }`}
                  style={{ animation: 'fadeIn 0.3s ease-in' }}
                >
                  <div className="flex items-start justify-between mb-3">
                    <div className="flex items-center gap-2">
                      {result.detection_result.is_anomalous ? (
                        <CheckCircle className="w-5 h-5 text-green-600" />
                      ) : (
                        <AlertTriangle className="w-5 h-5 text-red-600" />
                      )}
                      <span className="font-semibold">
                        {result.attack_type.replace('_', ' ').toUpperCase()}
                      </span>
                    </div>
                    <span className={`px-3 py-1 rounded-full text-sm font-semibold ${
                      result.detection_result.is_anomalous
                        ? 'bg-green-100 text-green-800'
                        : 'bg-red-100 text-red-800'
                    }`}>
                      {result.detection_result.is_anomalous ? '✓ DETECTED' : '✗ MISSED'}
                    </span>
                  </div>

                  <div className="grid grid-cols-2 gap-3 text-sm">
                    <div>
                      <span className="text-gray-600">Anomaly Score:</span>
                      <span className={`ml-2 font-bold ${getScoreColor(result.detection_result.anomaly_score)}`}>
                        {result.detection_result.anomaly_score.toFixed(4)}
                      </span>
                    </div>
                    <div>
                      <span className="text-gray-600">Threshold:</span>
                      <span className="ml-2 font-semibold text-gray-900">
                        {result.detection_result.threshold.toFixed(2)}
                      </span>
                    </div>
                    <div>
                      <span className="text-gray-600">Reconstruction Error:</span>
                      <span className="ml-2 font-semibold text-gray-900">
                        {result.detection_result.reconstruction_error.toFixed(4)}
                      </span>
                    </div>
                    <div>
                      <span className="text-gray-600">Perplexity:</span>
                      <span className="ml-2 font-semibold text-gray-900">
                        {result.detection_result.perplexity.toFixed(2)}
                      </span>
                    </div>
                  </div>

                  {result.detection_result.latency_ms && (
                    <div className="mt-2 text-xs text-gray-500">
                      Detection latency: {result.detection_result.latency_ms.toFixed(2)}ms
                    </div>
                  )}

                  <div className="mt-2 text-xs text-gray-400">
                    {new Date(result.timestamp).toLocaleString()}
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default AttackSimulation;
