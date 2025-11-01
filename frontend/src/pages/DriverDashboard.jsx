import { useEffect, useState } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '../components/ui/card';
import { Wrench, MapPin, Clock, CheckCircle2 } from 'lucide-react';
import { Button } from '../components/ui/button';
import { useNavigate } from 'react-router-dom';
import axiosInstance from '../api/axios';
import Loader from '../components/Loader';

const DriverDashboard = () => {
  const [tasks, setTasks] = useState([]);
  const [loading, setLoading] = useState(true);
  const navigate = useNavigate();

  useEffect(() => {
    fetchMyTasks();
  }, []);

  const fetchMyTasks = async () => {
    try {
      const response = await axiosInstance.get('/maintenance');
      setTasks(response.data.slice(0, 5));
    } catch (error) {
      console.error('Error fetching tasks:', error);
    } finally {
      setLoading(false);
    }
  };

  if (loading) return <Loader />;

  return (
    <div className="space-y-6 animate-fade-in">
      <div>
        <h1 className="text-3xl font-bold">Driver Dashboard</h1>
        <p className="text-muted-foreground">Your assigned tasks and activities</p>
      </div>

      <div className="grid gap-6 md:grid-cols-3">
        <Card className="shadow-card">
          <CardHeader className="flex flex-row items-center justify-between pb-2 space-y-0">
            <CardTitle className="text-sm font-medium">Today's Tasks</CardTitle>
            <Clock className="h-5 w-5 text-primary" />
          </CardHeader>
          <CardContent>
            <div className="text-3xl font-bold">3</div>
            <p className="text-xs text-muted-foreground mt-1">Scheduled for today</p>
          </CardContent>
        </Card>

        <Card className="shadow-card">
          <CardHeader className="flex flex-row items-center justify-between pb-2 space-y-0">
            <CardTitle className="text-sm font-medium">Completed</CardTitle>
            <CheckCircle2 className="h-5 w-5 text-success" />
          </CardHeader>
          <CardContent>
            <div className="text-3xl font-bold">12</div>
            <p className="text-xs text-muted-foreground mt-1">This week</p>
          </CardContent>
        </Card>

        <Card className="shadow-card">
          <CardHeader className="flex flex-row items-center justify-between pb-2 space-y-0">
            <CardTitle className="text-sm font-medium">Active Sites</CardTitle>
            <MapPin className="h-5 w-5 text-accent" />
          </CardHeader>
          <CardContent>
            <div className="text-3xl font-bold">2</div>
            <p className="text-xs text-muted-foreground mt-1">Current locations</p>
          </CardContent>
        </Card>
      </div>

      <Card className="shadow-card">
        <CardHeader>
          <CardTitle>Recent Maintenance Reports</CardTitle>
          <CardDescription>Your submitted reports</CardDescription>
        </CardHeader>
        <CardContent>
          {tasks.length === 0 ? (
            <p className="text-center text-muted-foreground py-8">No reports yet</p>
          ) : (
            <div className="space-y-3">
              {tasks.map((task) => (
                <div key={task.id} className="flex items-center justify-between p-4 border border-border rounded-lg hover:bg-muted transition-colors">
                  <div className="flex items-center gap-3">
                    <Wrench className="h-5 w-5 text-accent" />
                    <div>
                      <p className="font-medium">{task.issue_type}</p>
                      <p className="text-sm text-muted-foreground">{task.location}</p>
                    </div>
                  </div>
                  <span className={`text-xs px-2 py-1 rounded ${
                    task.status === 'Resolved' ? 'bg-success/10 text-success' :
                    task.status === 'In Progress' ? 'bg-primary/10 text-primary' :
                    'bg-accent/10 text-accent'
                  }`}>
                    {task.status}
                  </span>
                </div>
              ))}
            </div>
          )}
          <Button onClick={() => navigate('/maintenance')} className="w-full mt-4">
            View All Reports
          </Button>
        </CardContent>
      </Card>
    </div>
  );
};

export default DriverDashboard;
