import { useEffect, useState } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '../components/ui/card';
import { Wrench, FolderKanban, Users, CheckCircle2 } from 'lucide-react';
import axiosInstance from '../api/axios';
import Loader from '../components/Loader';

const ManagerDashboard = () => {
  const [stats, setStats] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchDashboardData();
  }, []);

  const fetchDashboardData = async () => {
    try {
      const response = await axiosInstance.get('/analytics/overview');
      setStats(response.data);
    } catch (error) {
      console.error('Error fetching dashboard data:', error);
    } finally {
      setLoading(false);
    }
  };

  if (loading) return <Loader />;

  const cards = [
    {
      title: 'Active Projects',
      value: stats?.active_projects || 0,
      icon: FolderKanban,
      description: 'Under supervision',
      color: 'text-primary',
    },
    {
      title: 'Pending Maintenance',
      value: stats?.pending_maintenance || 0,
      icon: Wrench,
      description: 'Awaiting review',
      color: 'text-accent',
    },
    {
      title: 'Team Members',
      value: stats?.team_size || 0,
      icon: Users,
      description: 'Active drivers',
      color: 'text-success',
    },
    {
      title: 'Completed Tasks',
      value: stats?.completed_tasks || 0,
      icon: CheckCircle2,
      description: 'This week',
      color: 'text-primary',
    },
  ];

  return (
    <div className="space-y-6 animate-fade-in">
      <div>
        <h1 className="text-3xl font-bold">Manager Dashboard</h1>
        <p className="text-muted-foreground">Monitor team activities and project progress</p>
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

      <Card className="shadow-card">
        <CardHeader>
          <CardTitle>Quick Actions</CardTitle>
          <CardDescription>Common management tasks</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="grid gap-4 md:grid-cols-3">
            <button className="p-4 border border-border rounded-lg hover:bg-muted transition-colors text-left">
              <Wrench className="h-6 w-6 text-accent mb-2" />
              <h3 className="font-semibold mb-1">Review Maintenance</h3>
              <p className="text-xs text-muted-foreground">Check pending reports</p>
            </button>
            <button className="p-4 border border-border rounded-lg hover:bg-muted transition-colors text-left">
              <FolderKanban className="h-6 w-6 text-primary mb-2" />
              <h3 className="font-semibold mb-1">Update Projects</h3>
              <p className="text-xs text-muted-foreground">Track progress</p>
            </button>
            <button className="p-4 border border-border rounded-lg hover:bg-muted transition-colors text-left">
              <Users className="h-6 w-6 text-success mb-2" />
              <h3 className="font-semibold mb-1">Manage Team</h3>
              <p className="text-xs text-muted-foreground">Assign tasks</p>
            </button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
};

export default ManagerDashboard;
