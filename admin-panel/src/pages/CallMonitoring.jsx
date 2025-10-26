import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import axios from 'axios';
import { API_BASE_URL } from '../config/api';
import { Phone, Clock, User, Calendar } from 'lucide-react';
import { format } from 'date-fns';

const CallMonitoring = () => {
  const [dateFilter, setDateFilter] = useState('today');

  const { data: callLogs, isLoading } = useQuery({
    queryKey: ['call-logs', dateFilter],
    queryFn: async () => {
      const response = await axios.get(`${API_BASE_URL}/call_monitoring_api.php?filter=${dateFilter}`);
      return response.data.data;
    },
    refetchInterval: 10000,
  });

  const getStatusColor = (status) => {
    const colors = {
      'connected': 'bg-green-100 text-green-700 border-green-200',
      'not_answered': 'bg-yellow-100 text-yellow-700 border-yellow-200',
      'busy': 'bg-orange-100 text-orange-700 border-orange-200',
      'failed': 'bg-red-100 text-red-700 border-red-200',
    };
    return colors[status] || 'bg-gray-100 text-gray-700 border-gray-200';
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Call Monitoring</h1>
          <p className="text-gray-600 mt-1">Real-time call tracking and monitoring</p>
        </div>
        <select
          value={dateFilter}
          onChange={(e) => setDateFilter(e.target.value)}
          className="px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500"
        >
          <option value="today">Today</option>
          <option value="yesterday">Yesterday</option>
          <option value="week">This Week</option>
          <option value="month">This Month</option>
        </select>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
        <div className="bg-white rounded-xl shadow-sm p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-gray-600 text-sm">Total Calls</p>
              <p className="text-3xl font-bold text-gray-900 mt-1">{callLogs?.stats?.total || 0}</p>
            </div>
            <Phone className="w-10 h-10 text-indigo-600" />
          </div>
        </div>
        <div className="bg-white rounded-xl shadow-sm p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-gray-600 text-sm">Connected</p>
              <p className="text-3xl font-bold text-green-600 mt-1">{callLogs?.stats?.connected || 0}</p>
            </div>
            <Phone className="w-10 h-10 text-green-600" />
          </div>
        </div>
        <div className="bg-white rounded-xl shadow-sm p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-gray-600 text-sm">Avg Duration</p>
              <p className="text-3xl font-bold text-purple-600 mt-1">{callLogs?.stats?.avg_duration || '0m'}</p>
            </div>
            <Clock className="w-10 h-10 text-purple-600" />
          </div>
        </div>
        <div className="bg-white rounded-xl shadow-sm p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-gray-600 text-sm">Success Rate</p>
              <p className="text-3xl font-bold text-orange-600 mt-1">{callLogs?.stats?.success_rate || 0}%</p>
            </div>
            <Calendar className="w-10 h-10 text-orange-600" />
          </div>
        </div>
      </div>

      {/* Call Logs Table */}
      <div className="bg-white rounded-xl shadow-sm overflow-hidden">
        {isLoading ? (
          <div className="flex items-center justify-center h-64">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-600"></div>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead className="bg-gray-50 border-b">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Time</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Telecaller</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Driver</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Phone</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Duration</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Status</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Feedback</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-200">
                {(callLogs?.calls || []).map((call) => (
                  <tr key={call.id} className="hover:bg-gray-50">
                    <td className="px-6 py-4 text-sm text-gray-900">
                      {call.call_time ? format(new Date(call.call_time), 'HH:mm:ss') : 'N/A'}
                    </td>
                    <td className="px-6 py-4">
                      <div className="flex items-center">
                        <div className="w-8 h-8 bg-indigo-100 rounded-full flex items-center justify-center mr-2">
                          <User className="w-4 h-4 text-indigo-600" />
                        </div>
                        <span className="text-sm font-medium text-gray-900">{call.telecaller_name}</span>
                      </div>
                    </td>
                    <td className="px-6 py-4 text-sm text-gray-900">{call.driver_name}</td>
                    <td className="px-6 py-4 text-sm text-gray-600">{call.phone}</td>
                    <td className="px-6 py-4 text-sm text-gray-600">{call.duration || '0s'}</td>
                    <td className="px-6 py-4">
                      <span className={`px-3 py-1 text-xs rounded-full border ${getStatusColor(call.status)}`}>
                        {call.status?.replace('_', ' ')}
                      </span>
                    </td>
                    <td className="px-6 py-4 text-sm text-gray-600">{call.feedback || '-'}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
};

export default CallMonitoring;
