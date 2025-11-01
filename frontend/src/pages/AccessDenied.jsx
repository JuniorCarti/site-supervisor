import { ShieldAlert } from 'lucide-react';
import { Button } from '../components/ui/button';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../hooks/useAuth';

const AccessDenied = () => {
  const navigate = useNavigate();
  const { user } = useAuth();

  const handleGoBack = () => {
    const dashboardPath = user ? `/${user.role.toLowerCase()}/dashboard` : '/login';
    navigate(dashboardPath);
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-background p-4">
      <div className="text-center max-w-md">
        <div className="inline-flex items-center justify-center w-20 h-20 rounded-full bg-destructive/10 mb-6">
          <ShieldAlert className="h-10 w-10 text-destructive" />
        </div>
        <h1 className="text-4xl font-bold mb-4">Access Denied</h1>
        <p className="text-muted-foreground mb-8">
          You don't have permission to access this page. Please contact your administrator if you believe this is an error.
        </p>
        <Button onClick={handleGoBack}>
          Go to Dashboard
        </Button>
      </div>
    </div>
  );
};

export default AccessDenied;
