import { useState } from 'react';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import axiosInstance from '@/api/axios';
import { useToast } from '@/hooks/use-toast';
import { Loader2 } from 'lucide-react';

const AIConsole = () => {
  const { toast } = useToast();
  const [loading, setLoading] = useState({});
  const [results, setResults] = useState({});

  // AI agent definitions
  const agents = [
    {
      id: 'sentinel',
      name: 'Sentinel Agent',
      description: 'Monitors financial health and anomalies',
      endpoint: '/ai/sentinel',
    },
    {
      id: 'quartermaster',
      name: 'Quartermaster Agent',
      description: 'Oversees inventory, resources, and supply forecasting',
      endpoint: '/ai/quartermaster',
    },
    {
      id: 'chancellor',
      name: 'Chancellor Agent',
      description: 'Analyzes overall performance and growth insights',
      endpoint: '/ai/chancellor',
    },
    {
      id: 'foreman',
      name: 'Foreman Agent',
      description: 'Optimizes logistics, routes, and workforce efficiency',
      endpoint: '/ai/foreman',
    },
  ];

  const runAgent = async (agent) => {
    setLoading((prev) => ({ ...prev, [agent.id]: true }));
    try {
      // Determine method
      const isSentinel = agent.id === 'sentinel';
      const method = isSentinel ? 'post' : 'get';
      const response = await axiosInstance[method](
        agent.endpoint,
        isSentinel ? {} : undefined
      );

      setResults((prev) => ({ ...prev, [agent.id]: response.data }));
      toast({
        title: `${agent.name} Analysis Complete`,
        description: 'AI insights have been generated successfully',
      });
    } catch (error) {
      console.error(`Error running ${agent.name}:`, error);
      toast({
        title: 'Error',
        description: `Failed to run ${agent.name} analysis`,
        variant: 'destructive',
      });
    } finally {
      setLoading((prev) => ({ ...prev, [agent.id]: false }));
    }
  };

  return (
    <div className="grid gap-6 md:grid-cols-2">
      {agents.map((agent) => (
        <Card key={agent.id} className="shadow-lg">
          <CardHeader>
            <CardTitle>{agent.name}</CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-gray-600 mb-4">{agent.description}</p>
            <Button
              onClick={() => runAgent(agent)}
              disabled={loading[agent.id]}
              className="w-full"
            >
              {loading[agent.id] ? (
                <>
                  <Loader2 className="animate-spin mr-2 h-4 w-4" /> Running...
                </>
              ) : (
                'Run Agent'
              )}
            </Button>

            {results[agent.id] && (
              <div className="mt-4 p-3 bg-gray-100 rounded-md text-sm">
                <pre className="whitespace-pre-wrap">
                  {JSON.stringify(results[agent.id], null, 2)}
                </pre>
              </div>
            )}
          </CardContent>
        </Card>
      ))}
    </div>
  );
};

export default AIConsole;
