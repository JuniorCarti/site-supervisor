import { useEffect, useState } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '../components/ui/card';
import { Users, Wrench, FolderKanban, DollarSign, TrendingUp, AlertTriangle } from 'lucide-react';
import axiosInstance from '../api/axios';
import Loader from '../components/Loader';
import { useToast } from '../hooks/use-toast';

const AdminDashboard = () => {
  const [stats, setStats] = useState(null);
  const [loading, setLoading] = useState(true);
  const { toast } = useToast();

  useEffect(() => {
    fetchDashboardData();
  }, []);

  const fetchDashboardData = async () => {
    try {
      const response = await axiosInstance.get('/analytics/overview');
      setStats(response.data);
    } catch (error) {
      toast({
        title: 'Error',
        description: 'Failed to load dashboard data',
        variant: 'destructive',
      });
    } finally {
      setLoading(false);
    }
  };

  if (loading) return <Loader />;

  const cards = [
    {
      title: 'Total Projects',
      value: stats?.total_projects || 0,
      icon: FolderKanban,
      description: 'Active and completed',
      color: 'text-primary',
    },
    {
      title: 'Maintenance Reports',
      value: stats?.total_maintenance || 0,
      icon: Wrench,
      description: 'This month',
      color: 'text-accent',
    },
    {
      title: 'Active Suppliers',
      value: stats?.total_suppliers || 0,
      icon: Users,
      description: 'Verified partners',
      color: 'text-success',
    },
    {
      title: 'Total Invoices',
      value: stats?.total_invoices || 0,
      icon: DollarSign,
      description: 'Pending and paid',
      color: 'text-destructive',
    },
  ];

  return (
    <div className="space-y-6 animate-fade-in">
      <div>
        <h1 className="text-3xl font-bold">Admin Dashboard</h1>
        <p className="text-muted-foreground">Overview of all operations and system status</p>
      </div>

      <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-4">
        {cards.map((card, index) => (
          <Card key={index} className="shadow-card hover:shadow-elevation transition-shadow">
            <CardHeader className="flex flex-row items-center justify-between pb-2 space-y-0">
              <CardTitle className="text-sm font-medium">{card.title}</CardTitle>
              <card.icon className={`h-5 w-5 ${card.color}`} />
            </CardHeader>
            <CardContent>
              <div className="text-3xl font-bold">{card.value}</div>
              <p className="text-xs text-muted-foreground mt-1">{card.description}</p>
            </CardContent>
          </Card>
        ))}
      </div>

      <div className="grid gap-6 md:grid-cols-2">
        <Card className="shadow-card">
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <TrendingUp className="h-5 w-5 text-success" />
              System Health
            </CardTitle>
            <CardDescription>Overall system performance</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              <div>
                <div className="flex items-center justify-between mb-2">
                  <span className="text-sm font-medium">API Response Time</span>
                  <span className="text-sm text-success">Excellent</span>
                </div>
                <div className="h-2 bg-muted rounded-full overflow-hidden">
                  <div className="h-full bg-success w-[92%]"></div>
                </div>
              </div>
              <div>
                <div className="flex items-center justify-between mb-2">
                  <span className="text-sm font-medium">Database Performance</span>
                  <span className="text-sm text-success">Good</span>
                </div>
                <div className="h-2 bg-muted rounded-full overflow-hidden">
                  <div className="h-full bg-success w-[85%]"></div>
                </div>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card className="shadow-card">
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <AlertTriangle className="h-5 w-5 text-accent" />
              Recent Alerts
            </CardTitle>
            <CardDescription>System notifications and warnings</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="space-y-3">
              <div className="flex items-start gap-3 p-3 bg-muted rounded-lg">
                <div className="h-2 w-2 rounded-full bg-accent mt-1.5"></div>
                <div className="flex-1">
                  <p className="text-sm font-medium">Project delay detected</p>
                  <p className="text-xs text-muted-foreground">Construction Site Alpha - 2 days behind</p>
                </div>
              </div>
              <div className="flex items-start gap-3 p-3 bg-muted rounded-lg">
                <div className="h-2 w-2 rounded-full bg-primary mt-1.5"></div>
                <div className="flex-1">
                  <p className="text-sm font-medium">New maintenance request</p>
                  <p className="text-xs text-muted-foreground">Equipment inspection needed</p>
                </div>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
};

export default AdminDashboard;
