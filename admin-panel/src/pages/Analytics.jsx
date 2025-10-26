import { useQuery } from '@tanstack/react-query';
import axios from 'axios';
import { API_BASE_URL } from '../config/api';
import { LineChart, Line, BarChart, Bar, AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts';
import { TrendingUp, TrendingDown, Activity } from 'lucide-react';

const Analytics = () => {
  const { data: analytics, isLoading } = useQuery({
    queryKey: ['analytics'],
    queryFn: async () => {
      const response = await axios.get(`${API_BASE_URL}/admin_analytics_api.php`);
      return response.data.data;
    },
  });

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-96">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-600"></div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold text-gray-900">Analytics & Reports</h1>
        <p className="text-gray-600 mt-1">Comprehensive insights and performance metrics</p>
      </div>

      {/* KPI Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div className="bg-gradient-to-br from-blue-500 to-blue-600 rounded-xl shadow-lg p-6 text-white">
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-lg font-semibold">Total Revenue</h3>
            <TrendingUp className="w-6 h-6" />
          </div>
          <p className="text-4xl font-bold">₹{analytics?.revenue?.total || 0}</p>
          <p className="text-blue-100 mt-2">+{analytics?.revenue?.growth || 0}% from last month</p>
        </div>

        <div className="bg-gradient-to-br from-green-500 to-green-600 rounded-xl shadow-lg p-6 text-white">
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-lg font-semibold">Conversion Rate</h3>
            <Activity className="w-6 h-6" />
          </div>
          <p className="text-4xl font-bold">{analytics?.conversion?.rate || 0}%</p>
          <p className="text-green-100 mt-2">{analytics?.conversion?.total || 0} conversions</p>
        </div>

        <div className="bg-gradient-to-br from-purple-500 to-purple-600 rounded-xl shadow-lg p-6 text-white">
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-lg font-semibold">Avg Call Duration</h3>
            <TrendingDown className="w-6 h-6" />
          </div>
          <p className="text-4xl font-bold">{analytics?.avg_duration || '0m'}</p>
          <p className="text-purple-100 mt-2">Across all calls</p>
        </div>
      </div>

      {/* Performance Trends */}
      <div className="bg-white rounded-xl shadow-sm p-6">
        <h3 className="text-lg font-semibold text-gray-900 mb-4">Performance Trends (30 Days)</h3>
        <ResponsiveContainer width="100%" height={400}>
          <AreaChart data={analytics?.trends || []}>
            <defs>
              <linearGradient id="colorCalls" x1="0" y1="0" x2="0" y2="1">
                <stop offset="5%" stopColor="#6366f1" stopOpacity={0.8}/>
                <stop offset="95%" stopColor="#6366f1" stopOpacity={0}/>
              </linearGradient>
            </defs>
            <CartesianGrid strokeDasharray="3 3" />
            <XAxis dataKey="date" />
            <YAxis />
            <Tooltip />
            <Legend />
            <Area type="monotone" dataKey="calls" stroke="#6366f1" fillOpacity={1} fill="url(#colorCalls)" />
          </AreaChart>
        </ResponsiveContainer>
      </div>

      {/* Telecaller Comparison */}
      <div className="bg-white rounded-xl shadow-sm p-6">
        <h3 className="text-lg font-semibold text-gray-900 mb-4">Telecaller Performance Comparison</h3>
        <ResponsiveContainer width="100%" height={400}>
          <BarChart data={analytics?.telecaller_comparison || []}>
            <CartesianGrid strokeDasharray="3 3" />
            <XAxis dataKey="name" />
            <YAxis />
            <Tooltip />
            <Legend />
            <Bar dataKey="calls" fill="#6366f1" />
            <Bar dataKey="connected" fill="#10b981" />
            <Bar dataKey="conversions" fill="#f59e0b" />
          </BarChart>
        </ResponsiveContainer>
      </div>
    </div>
  );
};

export default Analytics;
