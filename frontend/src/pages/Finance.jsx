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

const Finance = () => {
  const [invoices, setInvoices] = useState([]);
  const [suppliers, setSuppliers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [modalOpen, setModalOpen] = useState(false);
  const [deleteModal, setDeleteModal] = useState(false);
  const [selectedInvoice, setSelectedInvoice] = useState(null);
  const [formData, setFormData] = useState({ supplier_id: '', amount: '', status: 'pending' });
  const { user } = useAuth();
  const { toast } = useToast();

  useEffect(() => {
    fetchInvoices();
    fetchSuppliers();
  }, []);

  const fetchInvoices = async () => {
    try {
      const response = await axiosInstance.get('/finance/invoices');
      setInvoices(response.data);
    } catch (error) {
      console.error('Error fetching invoices:', error);
      toast({ title: 'Error', description: 'Failed to load invoices', variant: 'destructive' });
    } finally {
      setLoading(false);
    }
  };

  const fetchSuppliers = async () => {
    try {
      const response = await axiosInstance.get('/suppliers');
      setSuppliers(response.data);
    } catch (error) {
      console.error('Error fetching suppliers:', error);
    }
  };

  const getStatusColor = (status) => {
    switch (status?.toLowerCase()) {
      case 'approved':
        return 'bg-success/10 text-success border-success/20';
      case 'pending':
        return 'bg-accent/10 text-accent border-accent/20';
      case 'rejected':
        return 'bg-destructive/10 text-destructive border-destructive/20';
      default:
        return 'bg-muted/10 text-muted-foreground border-muted/20';
    }
  };

  const handleOpenModal = (invoice = null) => {
    if (invoice) {
      setSelectedInvoice(invoice);
      setFormData({
        supplier_id: invoice.supplier_id || '',
        amount: invoice.amount || '',
        status: invoice.status || 'pending',
      });
    } else {
      setSelectedInvoice(null);
      setFormData({ supplier_id: '', amount: '', status: 'pending' });
    }
    setModalOpen(true);
  };

  const handleSubmit = async () => {
    try {
      if (!formData.supplier_id || !formData.amount) {
        toast({ title: 'Error', description: 'Supplier and amount are required', variant: 'destructive' });
        return;
      }

      if (selectedInvoice) {
        // Update
        await axiosInstance.patch(`/finance/invoices/${selectedInvoice.id}`, formData);
        toast({ title: 'Success', description: 'Invoice updated successfully' });
      } else {
        // Create
        await axiosInstance.post('/finance/invoices', {
          supplier_id: parseInt(formData.supplier_id),
          amount: parseFloat(formData.amount),
        });
        toast({ title: 'Success', description: 'Invoice created successfully' });
      }

      setModalOpen(false);
      fetchInvoices();
    } catch (error) {
      console.error('Error saving invoice:', error);
      toast({ title: 'Error', description: 'Failed to save invoice', variant: 'destructive' });
    }
  };

  const confirmDelete = (invoice) => {
    setSelectedInvoice(invoice);
    setDeleteModal(true);
  };

  const handleDelete = async () => {
    try {
      await axiosInstance.delete(`/finance/invoices/${selectedInvoice.id}`);
      toast({ title: 'Deleted', description: 'Invoice deleted successfully' });
      setDeleteModal(false);
      fetchInvoices();
    } catch (error) {
      console.error('Error deleting invoice:', error);
      toast({ title: 'Error', description: 'Failed to delete invoice', variant: 'destructive' });
    }
  };

  const filteredInvoices = invoices.filter((invoice) =>
    invoice.supplier_id?.toString().includes(searchTerm.toLowerCase())
  );

  if (loading) return <Loader />;

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold">Finance</h1>
          <p className="text-muted-foreground">Manage invoices and financial records</p>
        </div>
        {(user?.role === 'Admin' || user?.role === 'Manager') && (
          <Button className="gap-2" onClick={() => handleOpenModal()}>
            <Plus className="h-4 w-4" />
            New Invoice
          </Button>
        )}
      </div>

      {/* Search */}
      <div className="relative">
        <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground" />
        <Input
          placeholder="Search by supplier ID..."
          value={searchTerm}
          onChange={(e) => setSearchTerm(e.target.value)}
          className="pl-10"
        />
      </div>

      {/* Invoices */}
      {filteredInvoices.length === 0 ? (
        <EmptyState
          title="No invoices found"
          description="Create your first invoice to get started"
          action={
            <Button className="gap-2" onClick={() => handleOpenModal()}>
              <Plus className="h-4 w-4" />
              Create Invoice
            </Button>
          }
        />
      ) : (
        <div className="grid gap-4">
          {filteredInvoices.map((invoice) => (
            <Card key={invoice.id} className="shadow-card hover:shadow-elevation transition-shadow">
              <CardHeader className="pb-3">
                <div className="flex items-start justify-between">
                  <div>
                    <CardTitle>Supplier #{invoice.supplier_id}</CardTitle>
                    <p className="text-sm text-muted-foreground mt-1">Invoice ID: {invoice.id}</p>
                  </div>
                  <Badge className={getStatusColor(invoice.status)}>{invoice.status}</Badge>
                </div>
              </CardHeader>
              <CardContent>
                <div className="grid grid-cols-2 md:grid-cols-3 gap-4 text-sm">
                  <div>
                    <p className="text-muted-foreground">Amount</p>
                    <p className="font-bold text-lg">${invoice.amount?.toLocaleString()}</p>
                  </div>
                  <div>
                    <p className="text-muted-foreground">Created</p>
                    <p className="font-medium">
                      {new Date(invoice.created_at).toLocaleDateString()}
                    </p>
                  </div>
                </div>
                <div className="flex justify-end gap-2 mt-3">
                  <Button size="sm" variant="outline" onClick={() => handleOpenModal(invoice)}>
                    <Pencil className="h-4 w-4" />
                  </Button>
                  <Button size="sm" variant="destructive" onClick={() => confirmDelete(invoice)}>
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
            <DialogTitle>{selectedInvoice ? 'Edit Invoice' : 'New Invoice'}</DialogTitle>
          </DialogHeader>
          <div className="space-y-3 py-2">
            {/* Supplier Dropdown */}
            <select
              className="w-full border rounded-md p-2"
              value={formData.supplier_id}
              onChange={(e) => setFormData({ ...formData, supplier_id: e.target.value })}
            >
              <option value="">Select Supplier</option>
              {suppliers.map((s) => (
                <option key={s.id} value={s.id}>
                  {s.name}
                </option>
              ))}
            </select>

            <Input
              placeholder="Amount"
              type="number"
              value={formData.amount}
              onChange={(e) => setFormData({ ...formData, amount: e.target.value })}
            />

            {selectedInvoice && (
              <select
                className="w-full border rounded-md p-2"
                value={formData.status}
                onChange={(e) => setFormData({ ...formData, status: e.target.value })}
              >
                <option value="pending">Pending</option>
                <option value="approved">Approved</option>
                <option value="rejected">Rejected</option>
              </select>
            )}
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setModalOpen(false)}>
              Cancel
            </Button>
            <Button onClick={handleSubmit}>{selectedInvoice ? 'Update' : 'Save'}</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Delete Modal */}
      <Dialog open={deleteModal} onOpenChange={setDeleteModal}>
        <DialogContent className="max-w-sm">
          <DialogHeader>
            <DialogTitle>Confirm Delete</DialogTitle>
          </DialogHeader>
          <p>Are you sure you want to delete this invoice? This action cannot be undone.</p>
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

export default Finance;
