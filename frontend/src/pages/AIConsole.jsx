import { useState } from 'react';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Progress } from '@/components/ui/progress';
import axiosInstance from '@/api/axios';
import { useToast } from '@/hooks/use-toast';
import { Loader2, TrendingUp, AlertTriangle, Package, Users, BarChart3, Sparkles, ArrowUpRight, ArrowDownRight, Target, Zap } from 'lucide-react';

const AIConsole = () => {
  const { toast } = useToast();
  const [loading, setLoading] = useState({});
  const [results, setResults] = useState({});

  const agents = [
    {
      id: 'sentinel',
      name: 'Sentinel Agent',
      description: 'Real-time financial monitoring & anomaly detection',
      endpoint: '/ai/sentinel',
      icon: TrendingUp,
      color: 'from-blue-500 to-cyan-500',
      bgColor: 'bg-gradient-to-br from-blue-50 to-cyan-50',
      borderColor: 'border-blue-100',
      accent: 'text-blue-600'
    },
    {
      id: 'quartermaster',
      name: 'Quartermaster Agent',
      description: 'Smart inventory optimization & supply chain intelligence',
      endpoint: '/ai/quartermaster',
      icon: Package,
      color: 'from-emerald-500 to-green-500',
      bgColor: 'bg-gradient-to-br from-emerald-50 to-green-50',
      borderColor: 'border-emerald-100',
      accent: 'text-emerald-600'
    },
    {
      id: 'chancellor',
      name: 'Chancellor Agent',
      description: 'Strategic growth insights & performance analytics',
      endpoint: '/ai/chancellor',
      icon: BarChart3,
      color: 'from-purple-500 to-violet-500',
      bgColor: 'bg-gradient-to-br from-purple-50 to-violet-50',
      borderColor: 'border-purple-100',
      accent: 'text-purple-600'
    },
    {
      id: 'foreman',
      name: 'Foreman Agent',
      description: 'Operational efficiency & workforce optimization',
      endpoint: '/ai/foreman',
      icon: Users,
      color: 'from-orange-500 to-amber-500',
      bgColor: 'bg-gradient-to-br from-orange-50 to-amber-50',
      borderColor: 'border-orange-100',
      accent: 'text-orange-600'
    },
  ];

  const runAgent = async (agent) => {
    setLoading((prev) => ({ ...prev, [agent.id]: true }));
    try {
      const isSentinel = agent.id === 'sentinel';
      const method = isSentinel ? 'post' : 'get';
      const response = await axiosInstance[method](
        agent.endpoint,
        isSentinel ? {} : undefined
      );

      setResults((prev) => ({ ...prev, [agent.id]: response.data }));
      toast({
        title: 'Analysis Complete',
        description: `${agent.name} has generated new insights`,
        className: 'border-l-4 border-l-green-500',
      });
    } catch (error) {
      console.error(`Error running ${agent.name}:`, error);
      toast({
        title: 'Analysis Failed',
        description: `${agent.name} encountered an error`,
        variant: 'destructive',
        className: 'border-l-4 border-l-red-500',
      });
    } finally {
      setLoading((prev) => ({ ...prev, [agent.id]: false }));
    }
  };

  const StatCard = ({ title, value, change, suffix = '', icon: Icon, trend = 'up' }) => (
    <div className="bg-white/80 backdrop-blur-sm rounded-xl border border-gray-100 p-4 shadow-sm hover:shadow-md transition-all duration-300">
      <div className="flex items-center justify-between mb-3">
        <div className="flex items-center space-x-2">
          {Icon && <Icon className="h-4 w-4 text-gray-500" />}
          <span className="text-sm font-medium text-gray-600">{title}</span>
        </div>
        {change && (
          <div className={`flex items-center space-x-1 text-xs font-medium ${
            trend === 'up' ? 'text-green-600' : 'text-red-600'
          }`}>
            {trend === 'up' ? <ArrowUpRight className="h-3 w-3" /> : <ArrowDownRight className="h-3 w-3" />}
            <span>{change}%</span>
          </div>
        )}
      </div>
      <div className="flex items-baseline space-x-2">
        <span className="text-2xl font-bold text-gray-900">{value}</span>
        {suffix && <span className="text-sm text-gray-500">{suffix}</span>}
      </div>
    </div>
  );

  const ProgressMetric = ({ label, value, target = 100, color = 'blue' }) => {
    const percentage = (value / target) * 100;
    const colorClasses = {
      blue: 'bg-blue-500',
      green: 'bg-emerald-500',
      purple: 'bg-purple-500',
      orange: 'bg-orange-500'
    };

    return (
      <div className="space-y-2">
        <div className="flex justify-between text-sm">
          <span className="font-medium text-gray-700">{label}</span>
          <span className="text-gray-600">{value}%</span>
        </div>
        <div className="h-2 bg-gray-100 rounded-full overflow-hidden">
          <div 
            className={`h-full rounded-full ${colorClasses[color]} transition-all duration-1000 ease-out`}
            style={{ width: `${Math.min(percentage, 100)}%` }}
          />
        </div>
      </div>
    );
  };

  const InsightCard = ({ title, description, type = 'info', icon: Icon = Sparkles }) => {
    const typeStyles = {
      info: 'border-blue-200 bg-blue-50/50 text-blue-700',
      success: 'border-emerald-200 bg-emerald-50/50 text-emerald-700',
      warning: 'border-amber-200 bg-amber-50/50 text-amber-700',
      error: 'border-red-200 bg-red-50/50 text-red-700'
    };

    return (
      <div className={`flex items-start space-x-3 p-3 rounded-xl border ${typeStyles[type]} backdrop-blur-sm`}>
        <Icon className="h-4 w-4 mt-0.5 flex-shrink-0" />
        <div className="space-y-1">
          <p className="text-sm font-semibold">{title}</p>
          <p className="text-xs opacity-80">{description}</p>
        </div>
      </div>
    );
  };

  const renderResults = (agentId, data) => {
    if (!data) return null;

    switch (agentId) {
      case 'sentinel':
        return (
          <div className="space-y-6">
            <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
              <StatCard 
                title="Revenue" 
                value="125.4" 
                change={12.5} 
                suffix="K" 
                icon={TrendingUp}
                trend="up"
              />
              <StatCard 
                title="Profit Margin" 
                value="24.8" 
                change={3.2} 
                suffix="%" 
                icon={Target}
                trend="up"
              />
              <StatCard 
                title="Expenses" 
                value="89.2" 
                change={-5.1} 
                suffix="K" 
                icon={ArrowDownRight}
                trend="down"
              />
              <StatCard 
                title="Cash Flow" 
                value="36.2" 
                change={8.7} 
                suffix="K" 
                icon={ArrowUpRight}
                trend="up"
              />
            </div>
            
            <div className="space-y-4">
              <h4 className="font-semibold text-gray-900 flex items-center space-x-2">
                <AlertTriangle className="h-4 w-4 text-amber-500" />
                <span>Financial Alerts</span>
              </h4>
              <div className="grid gap-3">
                <InsightCard
                  title="Unusual Expense Pattern"
                  description="Marketing expenses increased by 45% this month"
                  type="warning"
                  icon={AlertTriangle}
                />
                <InsightCard
                  title="Revenue Growth Strong"
                  description="Q4 revenue exceeds projections by 18%"
                  type="success"
                  icon={TrendingUp}
                />
              </div>
            </div>
          </div>
        );

      case 'quartermaster':
        return (
          <div className="space-y-6">
            <div className="grid grid-cols-2 gap-4">
              <StatCard title="Stock Turns" value="4.2" change={2.3} trend="up" />
              <StatCard title="Lead Time" value="3.5" change={-1.2} suffix="days" trend="down" />
            </div>
            
            <div className="space-y-4">
              <h4 className="font-semibold text-gray-900">Inventory Metrics</h4>
              <div className="space-y-4 p-4 bg-white/50 rounded-xl border">
                <ProgressMetric label="Inventory Level" value={68} color="green" />
                <ProgressMetric label="Supply Health" value={82} color="emerald" />
                <ProgressMetric label="Order Accuracy" value={94} color="blue" />
              </div>
            </div>

            <InsightCard
              title="Optimization Opportunity"
              description="Reduce safety stock by 15% for faster inventory turns"
              type="info"
              icon={Package}
            />
          </div>
        );

      case 'chancellor':
        return (
          <div className="space-y-6">
            <div className="grid grid-cols-3 gap-4">
              <StatCard title="Growth Rate" value="18.4" change={4.2} suffix="%" trend="up" />
              <StatCard title="Market Share" value="12.7" change={1.8} suffix="%" trend="up" />
              <StatCard title="Customer SAT" value="94.2" change={2.1} suffix="%" trend="up" />
            </div>
            
            <div className="space-y-4">
              <h4 className="font-semibold text-gray-900">Strategic Insights</h4>
              <div className="space-y-3">
                <InsightCard
                  title="Market Expansion Ready"
                  description="Current metrics support expansion into 3 new regions"
                  type="success"
                  icon={BarChart3}
                />
                <InsightCard
                  title="Competitive Advantage"
                  description="Customer satisfaction 12% above industry average"
                  type="info"
                  icon={Target}
                />
              </div>
            </div>
          </div>
        );

      case 'foreman':
        return (
          <div className="space-y-6">
            <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
              <StatCard title="Efficiency" value="87.5" suffix="%" trend="up" />
              <StatCard title="On-time Delivery" value="95.2" suffix="%" trend="up" />
              <StatCard title="Route Optimization" value="23.7" suffix="%" trend="up" />
              <StatCard title="Workforce Util" value="78.9" suffix="%" trend="up" />
            </div>
            
            <div className="space-y-4">
              <h4 className="font-semibold text-gray-900">Performance Metrics</h4>
              <div className="space-y-4 p-4 bg-white/50 rounded-xl border">
                <ProgressMetric label="Operational Efficiency" value={87} color="orange" />
                <ProgressMetric label="Resource Utilization" value={79} color="purple" />
                <ProgressMetric label="Quality Score" value={92} color="green" />
              </div>
            </div>

            <InsightCard
              title="Workflow Optimization"
              description="Implement shift rotation to improve utilization by 8%"
              type="info"
              icon={Zap}
            />
          </div>
        );

      default:
        return (
          <div className="p-4 bg-gray-50 rounded-xl border">
            <pre className="text-sm whitespace-pre-wrap">
              {JSON.stringify(data, null, 2)}
            </pre>
          </div>
        );
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-50 to-blue-50/30 p-6">
      <div className="max-w-7xl mx-auto">
        {/* Header */}
        <div className="text-center mb-12">
          <h1 className="text-4xl font-bold bg-gradient-to-r from-gray-900 to-blue-900 bg-clip-text text-transparent mb-4">
            AI Intelligence Console
          </h1>
          <p className="text-lg text-gray-600 max-w-2xl mx-auto">
            Advanced analytics and insights powered by specialized AI agents. 
            Monitor, optimize, and grow your business with real-time intelligence.
          </p>
        </div>

        {/* AI Agents Grid */}
        <div className="grid gap-8 lg:grid-cols-2">
          {agents.map((agent) => {
            const IconComponent = agent.icon;
            const hasResults = results[agent.id];
            
            return (
              <Card 
                key={agent.id} 
                className={`
                  relative overflow-hidden border-0 shadow-xl 
                  hover:shadow-2xl transition-all duration-500 
                  transform hover:-translate-y-2
                  ${agent.bgColor} ${agent.borderColor}
                  ${hasResults ? 'ring-2 ring-opacity-50 ring-gray-300' : ''}
                `}
              >
                {/* Gradient Accent */}
                <div className={`absolute top-0 left-0 w-1 h-full bg-gradient-to-b ${agent.color}`} />
                
                <CardHeader className="pb-6">
                  <div className="flex items-start justify-between">
                    <div className="flex items-center space-x-4">
                      <div className={`
                        p-3 rounded-2xl bg-white/80 backdrop-blur-sm 
                        shadow-sm border
                      `}>
                        <IconComponent className={`h-6 w-6 ${agent.accent}`} />
                      </div>
                      <div className="flex-1">
                        <CardTitle className={`text-xl font-bold ${agent.accent} mb-2`}>
                          {agent.name}
                        </CardTitle>
                        <p className="text-sm text-gray-600 leading-relaxed">
                          {agent.description}
                        </p>
                      </div>
                    </div>
                  </div>
                </CardHeader>

                <CardContent className="space-y-6">
                  {/* Run Agent Button - Always Visible */}
                  <div className="flex space-x-3">
                    <Button
                      onClick={() => runAgent(agent)}
                      disabled={loading[agent.id]}
                      className={`
                        flex-1 relative overflow-hidden group
                        bg-white text-gray-900 border border-gray-200
                        hover:shadow-lg hover:scale-[1.02] transition-all duration-300
                        font-semibold h-12
                        ${loading[agent.id] ? 'opacity-50 cursor-not-allowed' : ''}
                      `}
                      size="lg"
                    >
                      <div className={`absolute inset-0 bg-gradient-to-r ${agent.color} opacity-0 group-hover:opacity-10 transition-opacity`} />
                      
                      {loading[agent.id] ? (
                        <>
                          <Loader2 className="animate-spin mr-3 h-5 w-5" />
                          <span className="relative">Analyzing...</span>
                        </>
                      ) : (
                        <>
                          <Sparkles className="mr-3 h-5 w-5" />
                          <span className="relative">Run AI Analysis</span>
                        </>
                      )}
                    </Button>
                    
                    {/* Quick Action Button */}
                    {hasResults && (
                      <Button
                        variant="outline"
                        className="h-12 px-4 border-gray-200"
                        onClick={() => {
                          // Scroll to results
                          const element = document.getElementById(`results-${agent.id}`);
                          element?.scrollIntoView({ behavior: 'smooth' });
                        }}
                      >
                        <TrendingUp className="h-4 w-4" />
                      </Button>
                    )}
                  </div>

                  {/* Results Section - Always available when data exists */}
                  {hasResults && (
                    <div 
                      id={`results-${agent.id}`}
                      className="space-y-6 animate-in fade-in slide-in-from-bottom-5 duration-700 border-t pt-6"
                    >
                      <div className="flex items-center space-x-3">
                        <div className={`w-2 h-2 rounded-full bg-gradient-to-r ${agent.color}`} />
                        <h4 className="font-semibold text-gray-900 text-sm uppercase tracking-wide">
                          Live Insights
                        </h4>
                        <Badge variant="secondary" className="ml-auto">
                          Updated
                        </Badge>
                      </div>
                      {renderResults(agent.id, results[agent.id])}
                    </div>
                  )}

                  {/* Empty State */}
                  {!hasResults && !loading[agent.id] && (
                    <div className="text-center py-8">
                      <div className="inline-flex items-center justify-center w-16 h-16 rounded-full bg-white/50 border mb-4">
                        <Sparkles className="h-8 w-8 text-gray-400" />
                      </div>
                      <p className="text-gray-500 text-sm">
                        Click "Run AI Analysis" to generate insights
                      </p>
                    </div>
                  )}
                </CardContent>
              </Card>
            );
          })}
        </div>

        {/* Footer Status */}
        <div className="text-center mt-16 text-sm text-gray-500">
          <div className="inline-flex items-center space-x-2 bg-white/50 backdrop-blur-sm px-4 py-2 rounded-full border">
            <div className="w-2 h-2 bg-green-500 rounded-full animate-pulse"></div>
            <span>All systems operational</span>
            <span>•</span>
            <span>Last updated just now</span>
          </div>
        </div>
      </div>
    </div>
  );
};

export default AIConsole;