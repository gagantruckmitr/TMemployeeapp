import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import axios from 'axios';
import { API_BASE_URL } from '../config/api';
import { X, Loader } from 'lucide-react';

const AssignLeadsModal = ({ leadIds, onClose, onAssign }) => {
  const [selectedTelecaller, setSelectedTelecaller] = useState('');
  const [loading, setLoading] = useState(false);

  const { data: telecallers } = useQuery({
    queryKey: ['telecallers-list'],
    queryFn: async () => {
      const response = await axios.get(`${API_BASE_URL}/admin_telecallers_api.php`);
      return response.data.data;
    },
  });

  const handleAssign = async () => {
    if (!selectedTelecaller) return;
    setLoading(true);
    await onAssign(selectedTelecaller);
    setLoading(false);
  };

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div className="bg-white rounded-xl shadow-2xl w-full max-w-md p-6">
        <div className="flex items-center justify-between mb-6">
          <h2 className="text-2xl font-bold text-gray-900">Assign Leads</h2>
          <button onClick={onClose} className="p-2 hover:bg-gray-100 rounded-lg">
            <X className="w-5 h-5" />
          </button>
        </div>

        <div className="mb-6">
          <p className="text-gray-600">
            Assigning <span className="font-semibold text-indigo-600">{leadIds.length}</span> lead(s) to a telecaller
          </p>
        </div>

        <div className="mb-6">
          <label className="block text-sm font-medium text-gray-700 mb-2">
            Select Telecaller
          </label>
          <select
            value={selectedTelecaller}
            onChange={(e) => setSelectedTelecaller(e.target.value)}
            className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500"
          >
            <option value="">Choose a telecaller...</option>
            {(telecallers || []).map((tc) => (
              <option key={tc.id} value={tc.id}>
                {tc.name} - {tc.total_calls || 0} calls
              </option>
            ))}
          </select>
        </div>

        <div className="flex space-x-3">
          <button
            onClick={onClose}
            className="flex-1 px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50"
          >
            Cancel
          </button>
          <button
            onClick={handleAssign}
            disabled={!selectedTelecaller || loading}
            className="flex-1 px-4 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 disabled:opacity-50 flex items-center justify-center"
          >
            {loading ? <Loader className="animate-spin w-5 h-5" /> : 'Assign'}
          </button>
        </div>
      </div>
    </div>
  );
};

export default AssignLeadsModal;
