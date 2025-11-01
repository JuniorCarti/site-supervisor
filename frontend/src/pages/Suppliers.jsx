import { useState, useEffect } from 'react';
import { Plus, Search, Pencil, Trash2 } from 'lucide-react';
import { Button } from '../components/ui/button';
import { Input } from '../components/ui/input';
import { Card, CardContent, CardHeader, CardTitle } from '../components/ui/card';
import { Badge } from '../components/ui/badge';
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
import { useAuth } from '../hooks/useAuth';
import { useToast } from '../hooks/use-toast';

const Suppliers = () => {
  const [suppliers, setSuppliers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [modalOpen, setModalOpen] = useState(false);
  const [deleteModal, setDeleteModal] = useState(false);
  const [selectedSupplier, setSelectedSupplier] = useState(null);
  const [formData, setFormData] = useState({ name: '', contact: '', rating: '', last_bid_price: '' });
  const { user } = useAuth();
  const { toast } = useToast();

  useEffect(() => {
    fetchSuppliers();
  }, []);

  const fetchSuppliers = async () => {
    try {
      const response = await axiosInstance.get('/suppliers');
      setSuppliers(response.data);
    } catch (error) {
      console.error('Error fetching suppliers:', error);
      toast({ title: 'Error', description: 'Failed to load suppliers', variant: 'destructive' });
    } finally {
      setLoading(false);
    }
  };

  const handleOpenModal = (supplier = null) => {
    if (supplier) {
      setSelectedSupplier(supplier);
      setFormData({
        name: supplier.name || '',
        contact: supplier.contact || '',
        rating: supplier.rating || '',
        last_bid_price: supplier.last_bid_price || '',
      });
    } else {
      setSelectedSupplier(null);
      setFormData({ name: '', contact: '', rating: '', last_bid_price: '' });
    }
    setModalOpen(true);
  };

  const handleSubmit = async () => {
    try {
      if (selectedSupplier) {
        await axiosInstance.patch(`/suppliers/${selectedSupplier.id}`, formData);
        toast({ title: 'Updated', description: 'Supplier updated successfully' });
      } else {
        await axiosInstance.post('/suppliers', formData);
        toast({ title: 'Added', description: 'Supplier added successfully' });
      }
      setModalOpen(false);
      fetchSuppliers();
    } catch (error) {
      console.error('Error saving supplier:', error);
      toast({ title: 'Error', description: 'Failed to save supplier', variant: 'destructive' });
    }
  };

  const confirmDelete = (supplier) => {
    setSelectedSupplier(supplier);
    setDeleteModal(true);
  };

  const handleDelete = async () => {
    try {
      await axiosInstance.delete(`/suppliers/${selectedSupplier.id}`);
      toast({ title: 'Deleted', description: 'Supplier deleted successfully' });
      setDeleteModal(false);
      fetchSuppliers();
    } catch (error) {
      console.error('Error deleting supplier:', error);
      toast({ title: 'Error', description: 'Failed to delete supplier', variant: 'destructive' });
    }
  };

  const filteredSuppliers = suppliers.filter(
    (supplier) =>
      supplier.name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      supplier.contact?.toLowerCase().includes(searchTerm.toLowerCase())
  );

  if (loading) return <Loader />;

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold">Suppliers</h1>
          <p className="text-muted-foreground">
            Manage supplier relationships and bids
          </p>
        </div>
        {(user?.role === 'Admin' || user?.role === 'Manager') && (
          <Button className="gap-2" onClick={() => handleOpenModal()}>
            <Plus className="h-4 w-4" />
            Add Supplier
          </Button>
        )}
      </div>

      {/* Search */}
      <div className="relative">
        <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground" />
        <Input
          placeholder="Search suppliers..."
          value={searchTerm}
          onChange={(e) => setSearchTerm(e.target.value)}
          className="pl-10"
        />
      </div>

      {/* Supplier Cards */}
      {filteredSuppliers.length === 0 ? (
        <EmptyState
          title="No suppliers found"
          description="Add your first supplier to get started"
          action={
            <Button className="gap-2" onClick={() => handleOpenModal()}>
              <Plus className="h-4 w-4" />
              Add Supplier
            </Button>
          }
        />
      ) : (
        <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
          {filteredSuppliers.map((supplier) => (
            <Card key={supplier.id} className="shadow-card hover:shadow-elevation transition-shadow">
              <CardHeader className="pb-3">
                <div className="flex items-start justify-between">
                  <CardTitle className="text-lg">{supplier.name}</CardTitle>
                  <Badge className="bg-success/10 text-success border-success/20">
                    ★ {supplier.rating?.toFixed(1) || '0.0'}
                  </Badge>
                </div>
              </CardHeader>
              <CardContent className="space-y-2 text-sm">
                <div className="flex justify-between">
                  <span className="text-muted-foreground">Contact:</span>
                  <span className="font-medium">{supplier.contact || 'N/A'}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-muted-foreground">Last Bid:</span>
                  <span className="font-medium">
                    {supplier.last_bid_price ? `KSh ${supplier.last_bid_price.toFixed(2)}` : 'N/A'}
                  </span>
                </div>
                <div className="flex justify-between">
                  <span className="text-muted-foreground">Created:</span>
                  <span className="font-medium">
                    {new Date(supplier.created_at).toLocaleDateString()}
                  </span>
                </div>
                <div className="flex justify-end gap-2 pt-2">
                  <Button size="sm" variant="outline" onClick={() => handleOpenModal(supplier)}>
                    <Pencil className="h-4 w-4" />
                  </Button>
                  <Button size="sm" variant="destructive" onClick={() => confirmDelete(supplier)}>
                    <Trash2 className="h-4 w-4" />
                  </Button>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      )}

      {/* Add/Edit Modal */}
      <Dialog open={modalOpen} onOpenChange={setModalOpen}>
        <DialogContent className="max-w-md">
          <DialogHeader>
            <DialogTitle>{selectedSupplier ? 'Edit Supplier' : 'Add Supplier'}</DialogTitle>
          </DialogHeader>
          <div className="space-y-3 py-2">
            <Input
              placeholder="Supplier Name"
              value={formData.name}
              onChange={(e) => setFormData({ ...formData, name: e.target.value })}
            />
            <Input
              placeholder="Contact Email"
              value={formData.contact}
              onChange={(e) => setFormData({ ...formData, contact: e.target.value })}
            />
            <Input
              placeholder="Rating (0–5)"
              type="number"
              value={formData.rating}
              onChange={(e) => setFormData({ ...formData, rating: e.target.value })}
            />
            <Input
              placeholder="Last Bid Price"
              type="number"
              value={formData.last_bid_price}
              onChange={(e) => setFormData({ ...formData, last_bid_price: e.target.value })}
            />
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setModalOpen(false)}>
              Cancel
            </Button>
            <Button onClick={handleSubmit}>
              {selectedSupplier ? 'Update' : 'Save'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Delete Confirmation */}
      <Dialog open={deleteModal} onOpenChange={setDeleteModal}>
        <DialogContent className="max-w-sm">
          <DialogHeader>
            <DialogTitle>Confirm Delete</DialogTitle>
          </DialogHeader>
          <p>Are you sure you want to delete this supplier? This action cannot be undone.</p>
          <DialogFooter>
            <Button variant="outline" onClick={() => setDeleteModal(false)}>
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

export default Suppliers;
