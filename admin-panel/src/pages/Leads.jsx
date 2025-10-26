import { useState, useMemo, useCallback, memo } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import axios from 'axios';
import { API_BASE_URL } from '../config/api';
import AssignLeadsModal from '../components/AssignLeadsModal';
import {
  Search,
  Filter,
  RefreshCw,
  UserPlus,
  Phone,
  Calendar,
  TrendingUp,
  Users,
  CheckCircle,
  XCircle,
  Clock,
  AlertCircle,
  Download,
  Eye,
  PhoneCall
} from 'lucide-react';

// Memoized stat card component
const StatCard = memo(({ title, value, icon: Icon, gradient }) => (
  <div className={`${gradient} rounded-xl p-6 text-white shadow-lg`}>
    <div className="flex items-center justify-between">
      <div>
        <p className="text-sm font-medium opacity-90">{title}</p>
        <p className="text-3xl font-bold mt-1">{value}</p>
      </div>
      <Icon className="w-12 h-12 opacity-80" />
    </div>
  </div>
));

// Memoized lead row component
const LeadRow = memo(({ lead, isSelected, onSelect, onView, getStatusColor, getStatusIcon }) => (
  <tr className="hover:bg-gray-50 transition-colors">
    <td className="px-6 py-4">
      <input
        type="checkbox"
        checked={isSelected}
        onChange={() => onSelect(lead.id)}
        className="rounded border-gray-300 text-indigo-600 focus:ring-indigo-500 w-4 h-4 cursor-pointer"
      />
    </td>
    <td className="px-6 py-4">
      <div className="flex items-center">
        <div className="flex-shrink-0 h-10 w-10 bg-indigo-100 rounded-full flex items-center justify-center">
          <span className="text-indigo-600 font-semibold text-sm">
            {lead.driver_name?.charAt(0).toUpperCase() || 'U'}
          </span>
        </div>
        <div className="ml-4">
          <div className="font-medium text-gray-900">{lead.driver_name}</div>
          <div className="text-sm text-gray-500">ID: {lead.id}</div>
        </div>
      </div>
    </td>
    <td className="px-6 py-4">
      <div className="flex items-center text-gray-900">
        <Phone className="w-4 h-4 mr-2 text-gray-400" />
        {lead.phone}
      </div>
    </td>
    <td className="px-6 py-4">
      <span className={`inline-flex items-center gap-1.5 px-3 py-1.5 text-xs font-medium rounded-full border ${getStatusColor(lead.status)}`}>
        {getStatusIcon(lead.status)}
        {lead.status?.replace('_', ' ').toUpperCase()}
      </span>
    </td>
    <td className="px-6 py-4">
      {lead.assigned_to === 'Unassigned' ? (
        <span className="text-gray-400 italic">Unassigned</span>
      ) : (
        <div className="flex items-center">
          <div className="h-8 w-8 bg-green-100 rounded-full flex items-center justify-center mr-2">
            <span className="text-green-600 font-semibold text-xs">
              {lead.assigned_to?.charAt(0).toUpperCase()}
            </span>
          </div>
          <span className="text-gray-900 font-medium">{lead.assigned_to}</span>
        </div>
      )}
    </td>
    <td className="px-6 py-4">
      <div className="space-y-1">
        <div className="flex items-center text-sm text-gray-600">
          <PhoneCall className="w-3.5 h-3.5 mr-1.5 text-gray-400" />
          <span className="font-medium">{lead.total_calls || 0}</span>
          <span className="ml-1">total</span>
        </div>
        <div className="flex items-center text-sm text-green-600">
          <CheckCircle className="w-3.5 h-3.5 mr-1.5" />
          <span className="font-medium">{lead.connected_calls || 0}</span>
          <span className="ml-1">connected</span>
        </div>
      </div>
    </td>
    <td className="px-6 py-4">
      <div className="flex items-center text-sm text-gray-600">
        <Calendar className="w-4 h-4 mr-2 text-gray-400" />
        {lead.last_contact}
      </div>
    </td>
    <td className="px-6 py-4">
      <button
        onClick={() => onView(lead)}
        className="inline-flex items-center px-3 py-1.5 bg-indigo-50 text-indigo-600 rounded-lg hover:bg-indigo-100 transition-colors text-sm font-medium"
      >
        <Eye className="w-4 h-4 mr-1.5" />
        View
      </button>
    </td>
  </tr>
));

const Leads = () => {
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [assignModalOpen, setAssignModalOpen] = useState(false);
  const [selectedLeads, setSelectedLeads] = useState([]);
  const [selectedLead, setSelectedLead] = useState(null);
  const queryClient = useQueryClient();

  // Fetch leads data
  const { data: leadsResponse, isLoading, error } = useQuery({
    queryKey: ['leads', statusFilter],
    queryFn: async () => {
      const response = await axios.get(`${API_BASE_URL}/admin_leads_api.php?status=${statusFilter}`);
      return response.data;
    },
    staleTime: 10000, // Consider data fresh for 10 seconds
    cacheTime: 300000, // Keep in cache for 5 minutes
  });

  const leads = leadsResponse?.data || [];

  // Reassign mutation
  const reassignMutation = useMutation({
    mutationFn: async ({ leadIds, telecallerId }) => {
      await axios.post(`${API_BASE_URL}/admin_assign_leads_api.php`, {
        lead_ids: leadIds,
        telecaller_id: telecallerId
      });
    },
    onSuccess: () => {
      queryClient.invalidateQueries(['leads']);
      setSelectedLeads([]);
      setAssignModalOpen(false);
    },
  });

  // Memoized filtered leads
  const filteredLeads = useMemo(() => {
    if (!searchTerm) return leads;
    const search = searchTerm.toLowerCase();
    return leads.filter(lead =>
      lead.driver_name?.toLowerCase().includes(search) ||
      lead.phone?.includes(search)
    );
  }, [leads, searchTerm]);

  // Memoized statistics
  const stats = useMemo(() => ({
    total: leads.length,
    fresh: leads.filter(l => l.status === 'fresh').length,
    interested: leads.filter(l => l.status === 'interested').length,
    callback: leads.filter(l => l.status === 'callback').length,
    assigned: leads.filter(l => l.assigned_to !== 'Unassigned').length,
  }), [leads]);

  // Memoized callbacks
  const handleSelectLead = useCallback((leadId) => {
    setSelectedLeads(prev =>
      prev.includes(leadId)
        ? prev.filter(id => id !== leadId)
        : [...prev, leadId]
    );
  }, []);

  const handleSelectAll = useCallback(() => {
    setSelectedLeads(prev =>
      prev.length === filteredLeads.length && filteredLeads.length > 0
        ? []
        : filteredLeads.map(lead => lead.id)
    );
  }, [filteredLeads]);

  const handleRefresh = useCallback(() => {
    queryClient.invalidateQueries(['leads']);
  }, [queryClient]);

  const handleExport = useCallback(() => {
    const csvContent = [
      ['ID', 'Driver Name', 'Phone', 'Status', 'Assigned To', 'Total Calls', 'Connected Calls', 'Last Contact'],
      ...filteredLeads.map(lead => [
        lead.id,
        lead.driver_name,
        lead.phone,
        lead.status,
        lead.assigned_to,
        lead.total_calls,
        lead.connected_calls,
        lead.last_contact
      ])
    ].map(row => row.join(',')).join('\n');

    const blob = new Blob([csvContent], { type: 'text/csv' });
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `leads_${new Date().toISOString().split('T')[0]}.csv`;
    a.click();
    window.URL.revokeObjectURL(url);
  }, [filteredLeads]);

  // Memoized helper functions
  const getStatusColor = useCallback((status) => {
    const colors = {
      'fresh': 'bg-blue-100 text-blue-700 border-blue-200',
      'interested': 'bg-green-100 text-green-700 border-green-200',
      'not_interested': 'bg-red-100 text-red-700 border-red-200',
      'callback': 'bg-yellow-100 text-yellow-700 border-yellow-200',
      'no_response': 'bg-gray-100 text-gray-700 border-gray-200',
      'pending': 'bg-purple-100 text-purple-700 border-purple-200',
      'connected': 'bg-emerald-100 text-emerald-700 border-emerald-200',
    };
    return colors[status] || 'bg-gray-100 text-gray-700 border-gray-200';
  }, []);

  const getStatusIcon = useCallback((status) => {
    const icons = {
      'fresh': <AlertCircle className="w-4 h-4" />,
      'interested': <CheckCircle className="w-4 h-4" />,
      'not_interested': <XCircle className="w-4 h-4" />,
      'callback': <Clock className="w-4 h-4" />,
      'no_response': <Phone className="w-4 h-4" />,
      'connected': <PhoneCall className="w-4 h-4" />,
    };
    return icons[status] || <AlertCircle className="w-4 h-4" />;
  }, []);

  if (error) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="bg-red-50 border border-red-200 rounded-xl p-6 max-w-md">
          <XCircle className="w-12 h-12 text-red-500 mx-auto mb-4" />
          <h3 className="text-lg font-semibold text-red-900 text-center mb-2">Error Loading Leads</h3>
          <p className="text-red-700 text-center">{error.message}</p>
          <button
            onClick={handleRefresh}
            className="mt-4 w-full px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700"
          >
            Retry
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6 p-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-gray-900 flex items-center gap-3">
            <Users className="w-8 h-8 text-indigo-600" />
            Leads Management
          </h1>
          <p className="text-gray-600 mt-1">Manage, track, and assign leads to telecallers</p>
        </div>
        <div className="flex space-x-3">
          <button
            onClick={handleExport}
            className="flex items-center px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors"
          >
            <Download className="w-5 h-5 mr-2" />
            Export
          </button>
          <button
            onClick={handleRefresh}
            disabled={isLoading}
            className="flex items-center px-4 py-2 bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200 transition-colors disabled:opacity-50"
          >
            <RefreshCw className={`w-5 h-5 mr-2 ${isLoading ? 'animate-spin' : ''}`} />
            Refresh
          </button>
          <button
            disabled={selectedLeads.length === 0}
            onClick={() => setAssignModalOpen(true)}
            className="flex items-center px-4 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
          >
            <UserPlus className="w-5 h-5 mr-2" />
            Assign ({selectedLeads.length})
          </button>
        </div>
      </div>

      {/* Statistics Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <StatCard
          title="Total Leads"
          value={stats.total}
          icon={Users}
          gradient="bg-gradient-to-br from-blue-500 to-blue-600"
        />
        <StatCard
          title="Interested"
          value={stats.interested}
          icon={CheckCircle}
          gradient="bg-gradient-to-br from-green-500 to-green-600"
        />
        <StatCard
          title="Callbacks"
          value={stats.callback}
          icon={Clock}
          gradient="bg-gradient-to-br from-yellow-500 to-yellow-600"
        />
        <StatCard
          title="Fresh Leads"
          value={stats.fresh}
          icon={TrendingUp}
          gradient="bg-gradient-to-br from-purple-500 to-purple-600"
        />
      </div>

      {/* Filters and Search */}
      <div className="bg-white rounded-xl shadow-sm p-6 border border-gray-200">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-5 h-5" />
            <input
              type="text"
              placeholder="Search by name or phone..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full pl-10 pr-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-transparent transition-all"
            />
          </div>

          <div className="relative">
            <Filter className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-5 h-5" />
            <select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
              className="w-full pl-10 pr-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-transparent transition-all appearance-none bg-white"
            >
              <option value="all">All Status</option>
              <option value="fresh">Fresh Leads</option>
              <option value="interested">Interested</option>
              <option value="callback">Callback</option>
              <option value="not_interested">Not Interested</option>
              <option value="no_response">No Response</option>
              <option value="connected">Connected</option>
            </select>
          </div>
        </div>

        <div className="mt-4 flex items-center justify-between text-sm text-gray-600">
          <span>
            Showing <span className="font-semibold text-gray-900">{filteredLeads.length}</span> of{' '}
            <span className="font-semibold text-gray-900">{leads.length}</span> leads
          </span>
          {selectedLeads.length > 0 && (
            <span className="text-indigo-600 font-medium">
              {selectedLeads.length} lead(s) selected
            </span>
          )}
        </div>
      </div>

      {/* Leads Table */}
      {isLoading ? (
        <div className="bg-white rounded-xl shadow-sm p-12 flex flex-col items-center justify-center">
          <div className="animate-spin rounded-full h-16 w-16 border-b-4 border-indigo-600 mb-4"></div>
          <p className="text-gray-600 font-medium">Loading leads...</p>
        </div>
      ) : filteredLeads.length === 0 ? (
        <div className="bg-white rounded-xl shadow-sm p-12 text-center">
          <Users className="w-16 h-16 text-gray-300 mx-auto mb-4" />
          <h3 className="text-xl font-semibold text-gray-900 mb-2">No Leads Found</h3>
          <p className="text-gray-600">
            {searchTerm ? 'Try adjusting your search criteria' : 'No leads available at the moment'}
          </p>
        </div>
      ) : (
        <div className="bg-white rounded-xl shadow-sm overflow-hidden border border-gray-200">
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead className="bg-gray-50 border-b border-gray-200">
                <tr>
                  <th className="px-6 py-4 text-left">
                    <input
                      type="checkbox"
                      checked={selectedLeads.length === filteredLeads.length && filteredLeads.length > 0}
                      onChange={handleSelectAll}
                      className="rounded border-gray-300 text-indigo-600 focus:ring-indigo-500 w-4 h-4 cursor-pointer"
                    />
                  </th>
                  <th className="px-6 py-4 text-left text-xs font-semibold text-gray-600 uppercase tracking-wider">
                    Driver Info
                  </th>
                  <th className="px-6 py-4 text-left text-xs font-semibold text-gray-600 uppercase tracking-wider">
                    Contact
                  </th>
                  <th className="px-6 py-4 text-left text-xs font-semibold text-gray-600 uppercase tracking-wider">
                    Status
                  </th>
                  <th className="px-6 py-4 text-left text-xs font-semibold text-gray-600 uppercase tracking-wider">
                    Assigned To
                  </th>
                  <th className="px-6 py-4 text-left text-xs font-semibold text-gray-600 uppercase tracking-wider">
                    Call Stats
                  </th>
                  <th className="px-6 py-4 text-left text-xs font-semibold text-gray-600 uppercase tracking-wider">
                    Last Contact
                  </th>
                  <th className="px-6 py-4 text-left text-xs font-semibold text-gray-600 uppercase tracking-wider">
                    Actions
                  </th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-200">
                {filteredLeads.map((lead) => (
                  <LeadRow
                    key={lead.id}
                    lead={lead}
                    isSelected={selectedLeads.includes(lead.id)}
                    onSelect={handleSelectLead}
                    onView={setSelectedLead}
                    getStatusColor={getStatusColor}
                    getStatusIcon={getStatusIcon}
                  />
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* Assign Leads Modal */}
      {assignModalOpen && (
        <AssignLeadsModal
          leadIds={selectedLeads}
          onClose={() => setAssignModalOpen(false)}
          onAssign={(telecallerId) => {
            reassignMutation.mutate({ leadIds: selectedLeads, telecallerId });
          }}
        />
      )}

      {/* Lead Detail Modal */}
      {selectedLead && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-xl shadow-2xl w-full max-w-2xl max-h-[90vh] overflow-y-auto">
            <div className="sticky top-0 bg-white border-b border-gray-200 px-6 py-4 flex items-center justify-between">
              <h2 className="text-2xl font-bold text-gray-900">Lead Details</h2>
              <button
                onClick={() => setSelectedLead(null)}
                className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
              >
                <XCircle className="w-6 h-6 text-gray-500" />
              </button>
            </div>

            <div className="p-6 space-y-6">
              <div className="flex items-center space-x-4">
                <div className="h-20 w-20 bg-indigo-100 rounded-full flex items-center justify-center">
                  <span className="text-indigo-600 font-bold text-3xl">
                    {selectedLead.driver_name?.charAt(0).toUpperCase() || 'U'}
                  </span>
                </div>
                <div className="flex-1">
                  <h3 className="text-2xl font-bold text-gray-900">{selectedLead.driver_name}</h3>
                  <p className="text-gray-500">Lead ID: {selectedLead.id}</p>
                  <span className={`inline-flex items-center gap-1.5 px-3 py-1 text-xs font-medium rounded-full border mt-2 ${getStatusColor(selectedLead.status)}`}>
                    {getStatusIcon(selectedLead.status)}
                    {selectedLead.status?.replace('_', ' ').toUpperCase()}
                  </span>
                </div>
              </div>

              <div className="bg-gray-50 rounded-lg p-4 space-y-3">
                <h4 className="font-semibold text-gray-900 mb-3">Contact Information</h4>
                <div className="flex items-center text-gray-700">
                  <Phone className="w-5 h-5 mr-3 text-gray-400" />
                  <span className="font-medium">{selectedLead.phone}</span>
                </div>
              </div>

              <div className="bg-gray-50 rounded-lg p-4 space-y-3">
                <h4 className="font-semibold text-gray-900 mb-3">Assignment</h4>
                <div className="flex items-center justify-between">
                  <div className="flex items-center text-gray-700">
                    <Users className="w-5 h-5 mr-3 text-gray-400" />
                    <span>
                      {selectedLead.assigned_to === 'Unassigned' ? (
                        <span className="italic text-gray-400">Not assigned yet</span>
                      ) : (
                        <span className="font-medium">{selectedLead.assigned_to}</span>
                      )}
                    </span>
                  </div>
                  <button
                    onClick={() => {
                      setSelectedLeads([selectedLead.id]);
                      setAssignModalOpen(true);
                      setSelectedLead(null);
                    }}
                    className="px-3 py-1.5 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 text-sm font-medium"
                  >
                    Reassign
                  </button>
                </div>
              </div>

              <div className="bg-gray-50 rounded-lg p-4">
                <h4 className="font-semibold text-gray-900 mb-4">Call Statistics</h4>
                <div className="grid grid-cols-3 gap-4">
                  <div className="text-center">
                    <PhoneCall className="w-8 h-8 text-indigo-500 mx-auto mb-2" />
                    <p className="text-2xl font-bold text-gray-900">{selectedLead.total_calls || 0}</p>
                    <p className="text-sm text-gray-600">Total Calls</p>
                  </div>
                  <div className="text-center">
                    <CheckCircle className="w-8 h-8 text-green-500 mx-auto mb-2" />
                    <p className="text-2xl font-bold text-gray-900">{selectedLead.connected_calls || 0}</p>
                    <p className="text-sm text-gray-600">Connected</p>
                  </div>
                  <div className="text-center">
                    <TrendingUp className="w-8 h-8 text-purple-500 mx-auto mb-2" />
                    <p className="text-2xl font-bold text-gray-900">
                      {selectedLead.total_calls > 0 
                        ? Math.round((selectedLead.connected_calls / selectedLead.total_calls) * 100)
                        : 0}%
                    </p>
                    <p className="text-sm text-gray-600">Success Rate</p>
                  </div>
                </div>
              </div>

              <div className="flex space-x-3 pt-4 border-t border-gray-200">
                <button
                  onClick={() => setSelectedLead(null)}
                  className="flex-1 px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 font-medium"
                >
                  Close
                </button>
                <button
                  onClick={() => {
                    setSelectedLeads([selectedLead.id]);
                    setAssignModalOpen(true);
                    setSelectedLead(null);
                  }}
                  className="flex-1 px-4 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 font-medium"
                >
                  Assign Lead
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default Leads;
