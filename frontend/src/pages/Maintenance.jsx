import { useEffect, useState } from 'react';
import { Plus, Search, Filter, Pencil, Trash2 } from 'lucide-react';
import { Button } from '../components/ui/button';
import { Input } from '../components/ui/input';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '../components/ui/card';
import { Badge } from '../components/ui/badge';
import { Label } from '../components/ui/label';
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
} from '../components/ui/dialog';
import axiosInstance from '../api/axios';
import Loader from '../components/Loader';
import EmptyState from '../components/EmptyState';
import { useToast } from '../hooks/use-toast';
import { useAuth } from '../hooks/useAuth';

const Maintenance = () => {
  const [reports, setReports] = useState([]);
  const [loading, setLoading] = useState(true);
  const [fetching, setFetching] = useState(false);
  const [searchTerm, setSearchTerm] = useState('');
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [isDeleteConfirm, setIsDeleteConfirm] = useState(false);
  const [editMode, setEditMode] = useState(false);
  const [selectedReport, setSelectedReport] = useState(null);
  const [formData, setFormData] = useState({
    vehicle_id: '',
    description: '',
    severity: 'low',
    image_path: '',
    status: 'pending',
  });

  const { toast } = useToast();
  const { user } = useAuth();

  // 🔹 Fetch maintenance reports
  const fetchReports = async () => {
    setFetching(true);
    try {
      const response = await axiosInstance.get('/maintenance');
      setReports(response.data);
    } catch (error) {
      toast({
        title: 'Error',
        description: 'Failed to load maintenance reports',
        variant: 'destructive',
      });
    } finally {
      setLoading(false);
      setFetching(false);
    }
  };

  // Fetch on mount
  useEffect(() => {
    fetchReports();
  }, []);

  // 🔹 Handle input change
  const handleChange = (e) => {
    setFormData({ ...formData, [e.target.name]: e.target.value });
  };

  // 🔹 Create or Update
  const handleSubmit = async (e) => {
    e.preventDefault();

    try {
      if (editMode && selectedReport) {
        await axiosInstance.patch(`/maintenance/${selectedReport.id}`, {
          severity: formData.severity,
          status: formData.status,
        });
        toast({ title: 'Updated', description: 'Report updated successfully' });
      } else {
        await axiosInstance.post('/maintenance', {
          vehicle_id: formData.vehicle_id,
          description: formData.description,
          severity: formData.severity,
          image_path: formData.image_path,
        });
        toast({ title: 'Created', description: 'Report created successfully' });
      }

      setIsModalOpen(false);
      resetForm();
      await fetchReports(); // Refresh after submit
    } catch (error) {
      toast({
        title: 'Error',
        description: error.response?.data?.error || 'Failed to save report',
        variant: 'destructive',
      });
    }
  };

  // 🔹 Open edit modal
  const handleEdit = (report) => {
    setEditMode(true);
    setSelectedReport(report);
    setFormData({
      vehicle_id: report.vehicle_id,
      description: report.description,
      severity: report.severity,
      image_path: report.image_path || '',
      status: report.status || 'pending',
    });
    setIsModalOpen(true);
  };

  // 🔹 Delete report
  const handleDelete = async () => {
    try {
      await axiosInstance.delete(`/maintenance/${selectedReport.id}`);
      toast({ title: 'Deleted', description: 'Report deleted successfully' });
      setIsDeleteConfirm(false);
      setSelectedReport(null);
      await fetchReports(); // Refresh list
    } catch (error) {
      toast({
        title: 'Error',
        description: error.response?.data?.error || 'Failed to delete report',
        variant: 'destructive',
      });
    }
  };

  // 🔹 Reset form
  const resetForm = () => {
    setFormData({
      vehicle_id: '',
      description: '',
      severity: 'low',
      image_path: '',
      status: 'pending',
    });
    setEditMode(false);
    setSelectedReport(null);
  };

  // 🔹 Status color
  const getStatusColor = (status) => {
    switch (status) {
      case 'Resolved':
        return 'bg-green-100 text-green-800 border-green-300';
      case 'In Progress':
        return 'bg-blue-100 text-blue-800 border-blue-300';
      default:
        return 'bg-yellow-100 text-yellow-800 border-yellow-300';
    }
  };

  // 🔹 Filter reports
  const filteredReports = reports.filter(
    (report) =>
      report.description?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      report.vehicle_id?.toString().includes(searchTerm)
  );

  // 🔹 Show loader while fetching
  if (loading) return <Loader />;

  return (
    <div className="space-y-6">
      {/* Header Section */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold">Maintenance Reports</h1>
          <p className="text-muted-foreground">Track and manage all maintenance activities</p>
        </div>

        {(user?.role === 'Admin' || user?.role === 'Manager' || user?.role === 'Driver') && (
          <Button
            className="gap-2"
            onClick={() => {
              resetForm();
              setIsModalOpen(true);
            }}
          >
            <Plus className="h-4 w-4" />
            New Report
          </Button>
        )}
      </div>

      {/* Search & Filter */}
      <div className="flex gap-4">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground" />
          <Input
            placeholder="Search reports..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="pl-10"
          />
        </div>
        <Button variant="outline" className="gap-2">
          <Filter className="h-4 w-4" />
          Filter
        </Button>
      </div>

      {/* Loader for re-fetching */}
      {fetching && (
        <p className="text-center text-sm text-muted-foreground animate-pulse">Refreshing reports...</p>
      )}

      {/* Reports Display */}
      {filteredReports.length === 0 ? (
        <EmptyState
          title="No maintenance reports"
          description="Get started by creating your first maintenance report"
          action={
            <Button
              className="gap-2"
              onClick={() => {
                resetForm();
                setIsModalOpen(true);
              }}
            >
              <Plus className="h-4 w-4" />
              Create Report
            </Button>
          }
        />
      ) : (
        <div className="grid gap-4">
          {filteredReports.map((report) => (
            <Card key={report.id} className="shadow-card hover:shadow-lg transition-shadow">
              <CardHeader className="pb-3">
                <div className="flex items-start justify-between">
                  <div>
                    <CardTitle>Vehicle ID: {report.vehicle_id}</CardTitle>
                    <CardDescription className="mt-1">
                      Severity: {report.severity?.toUpperCase()}
                    </CardDescription>
                  </div>
                  <Badge className={getStatusColor(report.status)}>{report.status}</Badge>
                </div>
              </CardHeader>

              <CardContent>
                <p className="text-sm text-muted-foreground mb-3">{report.description}</p>

                <div className="flex items-center justify-between text-xs text-muted-foreground">
                  <span>Created: {new Date(report.created_at).toLocaleDateString()}</span>
                  {(user?.role === 'Admin' || user?.role === 'Manager') && (
                    <div className="flex gap-2">
                      <Button
                        variant="outline"
                        size="sm"
                        onClick={() => handleEdit(report)}
                        className="gap-1"
                      >
                        <Pencil className="h-3 w-3" />
                        Edit
                      </Button>
                      <Button
                        variant="destructive"
                        size="sm"
                        onClick={() => {
                          setSelectedReport(report);
                          setIsDeleteConfirm(true);
                        }}
                        className="gap-1"
                      >
                        <Trash2 className="h-3 w-3" />
                        Delete
                      </Button>
                    </div>
                  )}
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      )}

      {/* 🧾 Create/Edit Modal */}
      <Dialog open={isModalOpen} onOpenChange={setIsModalOpen}>
        <DialogContent className="max-w-md">
          <DialogHeader>
            <DialogTitle>
              {editMode ? 'Edit Maintenance Report' : 'Create Maintenance Report'}
            </DialogTitle>
          </DialogHeader>
          <form onSubmit={handleSubmit} className="space-y-4">
            {!editMode && (
              <>
                <div>
                  <Label>Vehicle ID</Label>
                  <Input
                    name="vehicle_id"
                    placeholder="Enter vehicle ID"
                    value={formData.vehicle_id}
                    onChange={handleChange}
                    required
                  />
                </div>

                <div>
                  <Label>Description</Label>
                  <Input
                    name="description"
                    placeholder="Describe the issue"
                    value={formData.description}
                    onChange={handleChange}
                    required
                  />
                </div>

                <div>
                  <Label>Image Path (optional)</Label>
                  <Input
                    name="image_path"
                    placeholder="Image URL or file path"
                    value={formData.image_path}
                    onChange={handleChange}
                  />
                </div>
              </>
            )}

            <div>
              <Label>Severity</Label>
              <select
                name="severity"
                value={formData.severity}
                onChange={handleChange}
                className="w-full border rounded-md px-3 py-2"
              >
                <option value="low">Low</option>
                <option value="moderate">Moderate</option>
                <option value="critical">Critical</option>
              </select>
            </div>

            {editMode && (
              <div>
                <Label>Status</Label>
                <select
                  name="status"
                  value={formData.status}
                  onChange={handleChange}
                  className="w-full border rounded-md px-3 py-2"
                >
                  <option value="pending">Pending</option>
                  <option value="In Progress">In Progress</option>
                  <option value="Resolved">Resolved</option>
                </select>
              </div>
            )}

            <DialogFooter>
              <Button type="button" variant="outline" onClick={() => setIsModalOpen(false)}>
                Cancel
              </Button>
              <Button type="submit">{editMode ? 'Save Changes' : 'Submit Report'}</Button>
            </DialogFooter>
          </form>
        </DialogContent>
      </Dialog>

      {/* ❌ Delete Confirmation Modal */}
      <Dialog open={isDeleteConfirm} onOpenChange={setIsDeleteConfirm}>
        <DialogContent className="max-w-sm">
          <DialogHeader>
            <DialogTitle>Confirm Delete</DialogTitle>
          </DialogHeader>
          <p>Are you sure you want to delete this maintenance report?</p>
          <DialogFooter>
            <Button variant="outline" onClick={() => setIsDeleteConfirm(false)}>
              Cancel
            </Button>
            <Button variant="destructive" onClick={handleDelete}>
              Delete
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
};

export default Maintenance;
