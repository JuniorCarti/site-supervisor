import { Toaster } from "@/components/ui/toaster";
import { Toaster as Sonner } from "@/components/ui/sonner";
import { TooltipProvider } from "@/components/ui/tooltip";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import { SidebarProvider } from "@/components/ui/sidebar";
import { AuthProvider } from "./context/AuthContext";
import RoleGuard from "./components/RoleGuard";
import Navbar from "./components/Navbar";
import AppSidebar from "./components/AppSidebar";
import { useAuth } from "./hooks/useAuth";
// Auth Pages
import Login from "./pages/Login";
import Register from "./pages/Register";
import AccessDenied from "./pages/AccessDenied";

// Dashboard Pages
import AdminDashboard from "./pages/AdminDashboard";
import ManagerDashboard from "./pages/ManagerDashboard";
import DriverDashboard from "./pages/DriverDashboard";

// Feature Pages
import Maintenance from "./pages/Maintenance";
import Projects from "./pages/Projects";
import Suppliers from "./pages/Suppliers";
import Finance from "./pages/Finance";
import AIConsole from "./pages/AIConsole";
import Analytics from "./pages/Analytics";

import NotFound from "./pages/NotFound";

const queryClient = new QueryClient();

const DashboardLayout = ({ children }: { children: React.ReactNode }) => {
  return (
    <div className="flex min-h-screen w-full">
      <AppSidebar />
      <div className="flex-1 flex flex-col">
        <Navbar />
        <main className="flex-1 p-6 bg-muted/20">
          {children}
        </main>
      </div>
    </div>
  );
};

const HomeRedirect = () => {
  const { user } = useAuth();
  if (!user) return <Navigate to="/login" replace />;
  const path = `/${user.role.toLowerCase()}/dashboard`;
  return <Navigate to={path} replace />;
};

const App = () => (
  <QueryClientProvider client={queryClient}>
    <TooltipProvider>
      <Toaster />
      <Sonner />
      <BrowserRouter>
        <AuthProvider>
          <Routes>
            {/* Public Routes */}
            <Route path="/login" element={<Login />} />
            <Route path="/register" element={<Register />} />
            <Route path="/access-denied" element={<AccessDenied />} />

            {/* Protected Routes with Layout */}
            <Route
              path="/*"
              element={
                <RoleGuard allowedRoles={['Admin', 'Manager', 'Driver']}>
                  <SidebarProvider>
                    <DashboardLayout>
                      <Routes>
                        {/* Dashboard Routes */}
                        <Route path="/" element={<HomeRedirect />} />
                        <Route 
                          path="/admin/dashboard" 
                          element={
                            <RoleGuard allowedRoles={['Admin']}>
                              <AdminDashboard />
                            </RoleGuard>
                          } 
                        />
                        <Route 
                          path="/manager/dashboard" 
                          element={
                            <RoleGuard allowedRoles={['Manager']}>
                              <ManagerDashboard />
                            </RoleGuard>
                          } 
                        />
                        <Route 
                          path="/driver/dashboard" 
                          element={
                            <RoleGuard allowedRoles={['Driver']}>
                              <DriverDashboard />
                            </RoleGuard>
                          } 
                        />

                        {/* Feature Routes */}
                        <Route path="/maintenance" element={<Maintenance />} />
                        <Route path="/projects" element={<Projects />} />
                        <Route path="/suppliers" element={<Suppliers />} />
                        <Route path="/finance" element={<Finance />} />
                        <Route path="/ai" element={<AIConsole />} />
                        <Route 
                          path="/analytics" 
                          element={
                            <RoleGuard allowedRoles={['Admin', 'Manager']}>
                              <Analytics />
                            </RoleGuard>
                          } 
                        />

                        {/* 404 */}
                        <Route path="*" element={<NotFound />} />
                      </Routes>
                    </DashboardLayout>
                  </SidebarProvider>
                </RoleGuard>
              }
            />
          </Routes>
        </AuthProvider>
      </BrowserRouter>
    </TooltipProvider>
  </QueryClientProvider>
);

export default App;
