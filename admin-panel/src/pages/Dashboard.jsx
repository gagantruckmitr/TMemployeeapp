import { useQuery } from '@tanstack/react-query';
import axios from 'axios';
import { API_BASE_URL } from '../config/api';
import {
  Users, Phone, TrendingUp, Activity, Zap, Target, Award, Clock,
  UserCheck, PhoneCall, PhoneIncoming, PhoneMissed, Calendar,
  BarChart3, Sparkles, Crown, CheckCircle2, XCircle, AlertCircle,
  Timer, Briefcase, Shield, ArrowUpRight, ArrowDownRight, TrendingDown
} from 'lucide-react';
import {
  BarChart, Bar, PieChart, Pie, Cell, XAxis, YAxis, CartesianGrid,
  Tooltip, Legend, ResponsiveContainer, AreaChart, Area, LineChart, Line,
  RadarChart, PolarGrid, PolarAngleAxis, PolarRadiusAxis, Radar
} from 'recharts';

const Dashboard = () => {
  const { data: stats, isLoading, error } = useQuery({
    queryKey: ['dashboard-stats'],
    queryFn: async () => {
      const response = await axios.get(`${API_BASE_URL}/admin_dashboard_stats.php`);
      console.log('API Response:', response.data);

      // Handle different response structures
      if (response.data && response.data.success && response.data.data) {
        return response.data.data;
      }

      // If data is directly in response
      if (response.data && !response.data.success) {
        return response.data;
      }

      // Return empty object as fallback
      return {
        total_telecallers: 0,
        total_managers: 0,
        total_drivers: 0,
        total_calls: 0,
        connected_calls: 0,
        calls_today: 0,
        active_calls: 0,
        conversion_rate: 0,
        call_trends: [],
        call_distribution: [],
        top_performers: [],
        recent_activity: [],
        telecallers_list: [],
        managers_list: [],
        total_admins: 0
      };
    },
    refetchInterval: 10000,
  });

  const COLORS = ['#6366f1', '#8b5cf6', '#ec4899', '#f59e0b', '#10b981', '#06b6d4', '#f43f5e'];

  if (isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-white">
        <div className="relative">
          <div className="w-20 h-20 border-4 border-indigo-500 border-t-transparent rounded-full animate-spin"></div>
          <div className="absolute top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2">
            <Zap className="w-8 h-8 text-indigo-500 animate-pulse" />
          </div>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-white p-6">
        <div className="text-center">
          <div className="w-20 h-20 bg-red-100 rounded-full flex items-center justify-center mx-auto mb-4">
            <Activity className="w-10 h-10 text-red-500" />
          </div>
          <h2 className="text-2xl font-bold text-gray-800 mb-2">Failed to Load Dashboard</h2>
          <p className="text-gray-600 mb-4">Error: {error.message}</p>
          <button
            onClick={() => window.location.reload()}
            className="px-6 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700"
          >
            Retry
          </button>
        </div>
      </div>
    );
  }

  const statCards = [
    {
      title: 'Total Telecallers',
      value: stats?.total_telecallers || 0,
      change: '+12%',
      icon: Users,
      gradient: 'from-indigo-500 to-purple-600',
      iconBg: 'bg-gradient-to-br from-indigo-500 to-purple-600',
      bgAccent: 'bg-indigo-50',
      trend: 'up'
    },
    {
      title: 'Active Calls',
      value: stats?.active_calls || 0,
      change: 'Live',
      icon: Phone,
      gradient: 'from-emerald-500 to-teal-600',
      iconBg: 'bg-gradient-to-br from-emerald-500 to-teal-600',
      bgAccent: 'bg-emerald-50',
      trend: 'up'
    },
    {
      title: 'Calls Today',
      value: stats?.calls_today || 0,
      change: '+8%',
      icon: Activity,
      gradient: 'from-blue-500 to-cyan-600',
      iconBg: 'bg-gradient-to-br from-blue-500 to-cyan-600',
      bgAccent: 'bg-blue-50',
      trend: 'up'
    },
    {
      title: 'Conversion Rate',
      value: `${stats?.conversion_rate || 0}%`,
      change: '+2.5%',
      icon: TrendingUp,
      gradient: 'from-orange-500 to-pink-600',
      iconBg: 'bg-gradient-to-br from-orange-500 to-pink-600',
      bgAccent: 'bg-orange-50',
      trend: 'up'
    },
  ];

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-50 via-white to-gray-50 p-6">
      {/* Elegant Background Pattern */}
      <div className="fixed inset-0 bg-[radial-gradient(circle_at_20%_30%,rgba(99,102,241,0.03),transparent_40%),radial-gradient(circle_at_80%_70%,rgba(139,92,246,0.03),transparent_40%),radial-gradient(circle_at_50%_50%,rgba(236,72,153,0.02),transparent_50%)] pointer-events-none"></div>
      <div className="fixed inset-0 bg-[linear-gradient(to_right,#80808008_1px,transparent_1px),linear-gradient(to_bottom,#80808008_1px,transparent_1px)] bg-[size:64px_64px] pointer-events-none"></div>

      <div className="relative z-10 max-w-[1800px] mx-auto">
        {/* Premium Header */}
        <div className="bg-white rounded-3xl p-8 mb-8 border border-gray-100 shadow-[0_8px_30px_rgb(0,0,0,0.04)] hover:shadow-[0_8px_40px_rgb(0,0,0,0.06)] transition-all duration-300">
          <div className="flex items-center justify-between flex-wrap gap-4">
            <div className="flex items-center gap-4">
              <div className="relative">
                <div className="absolute inset-0 bg-gradient-to-br from-indigo-500 to-purple-600 rounded-2xl blur-xl opacity-30 animate-pulse"></div>
                <div className="relative bg-gradient-to-br from-indigo-500 to-purple-600 p-3.5 rounded-2xl shadow-lg">
                  <Sparkles className="w-9 h-9 text-white" />
                </div>
              </div>
              <div>
                <h1 className="text-4xl font-bold bg-gradient-to-r from-gray-900 via-gray-800 to-gray-900 bg-clip-text text-transparent mb-1">
                  Dashboard Overview
                </h1>
                <p className="text-gray-500 text-base font-medium">Real-time business intelligence & analytics</p>
              </div>
            </div>
            <div className="flex items-center gap-4">
              <div className="flex items-center gap-2.5 bg-gradient-to-r from-emerald-50 to-teal-50 px-5 py-2.5 rounded-full border border-emerald-200/50 shadow-sm">
                <div className="relative">
                  <div className="w-2.5 h-2.5 bg-emerald-500 rounded-full animate-pulse"></div>
                  <div className="absolute inset-0 w-2.5 h-2.5 bg-emerald-500 rounded-full animate-ping"></div>
                </div>
                <span className="text-emerald-700 font-semibold text-sm">Live</span>
              </div>
              <div className="bg-gray-50 px-5 py-2.5 rounded-full border border-gray-200 shadow-sm">
                <span className="text-gray-700 font-semibold text-sm flex items-center gap-2">
                  <Clock className="w-4 h-4" />
                  {new Date().toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })}
                </span>
              </div>
            </div>
          </div>
        </div>

        {/* Premium Stats Cards */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
          {statCards.map((stat, index) => (
            <div
              key={index}
              className="group relative bg-white rounded-2xl p-6 border border-gray-100 hover:border-gray-200 transition-all duration-300 hover:scale-[1.02] hover:shadow-[0_8px_30px_rgb(0,0,0,0.08)] cursor-pointer overflow-hidden"
            >
              {/* Animated gradient background on hover */}
              <div className={`absolute inset-0 bg-gradient-to-br ${stat.gradient} opacity-0 group-hover:opacity-[0.03] transition-opacity duration-500`}></div>

              <div className="relative z-10">
                <div className="flex items-center justify-between mb-5">
                  <div className="relative">
                    <div className={`absolute inset-0 bg-gradient-to-br ${stat.gradient} rounded-xl blur-lg opacity-0 group-hover:opacity-40 transition-opacity duration-300`}></div>
                    <div className={`relative ${stat.iconBg} p-3.5 rounded-xl shadow-md group-hover:scale-110 group-hover:rotate-3 transition-all duration-300`}>
                      <stat.icon className="w-6 h-6 text-white" />
                    </div>
                  </div>
                  <div className={`flex items-center gap-1.5 ${stat.trend === 'up' ? 'bg-emerald-50 text-emerald-600 border-emerald-200/50' : 'bg-red-50 text-red-600 border-red-200/50'} px-3 py-1.5 rounded-full border`}>
                    {stat.trend === 'up' ? <ArrowUpRight className="w-3.5 h-3.5" /> : <ArrowDownRight className="w-3.5 h-3.5" />}
                    <span className="text-xs font-bold">{stat.change}</span>
                  </div>
                </div>
                <h3 className="text-gray-500 text-xs font-bold mb-2 uppercase tracking-wider">{stat.title}</h3>
                <p className="text-3xl font-bold text-gray-900 mb-4">{stat.value}</p>
                <div className="relative h-1 w-full bg-gray-100 rounded-full overflow-hidden">
                  <div className={`absolute inset-y-0 left-0 bg-gradient-to-r ${stat.gradient} rounded-full animate-[shimmer_2s_infinite]`} style={{ width: '75%' }}></div>
                </div>
              </div>
            </div>
          ))}
        </div>

        {/* Enhanced Secondary Stats */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
          <div className="bg-white rounded-2xl p-6 border border-gray-100 hover:shadow-[0_8px_30px_rgb(0,0,0,0.08)] transition-all group">
            <div className="flex items-center justify-between mb-4">
              <div className="bg-gradient-to-br from-blue-500 to-cyan-600 p-3 rounded-xl shadow-md group-hover:scale-110 transition-transform">
                <Target className="w-6 h-6 text-white" />
              </div>
              <Briefcase className="w-5 h-5 text-gray-300" />
            </div>
            <p className="text-gray-500 text-xs font-bold uppercase tracking-wider mb-2">Total Drivers</p>
            <p className="text-3xl font-bold text-gray-900">{stats?.total_drivers || 0}</p>
            <div className="mt-3 flex items-center gap-2 text-xs">
              <span className="text-blue-600 font-semibold">Database</span>
              <div className="h-1 flex-1 bg-gray-100 rounded-full overflow-hidden">
                <div className="h-full bg-gradient-to-r from-blue-500 to-cyan-600 w-3/4"></div>
              </div>
            </div>
          </div>

          <div className="bg-white rounded-2xl p-6 border border-gray-100 hover:shadow-[0_8px_30px_rgb(0,0,0,0.08)] transition-all group">
            <div className="flex items-center justify-between mb-4">
              <div className="bg-gradient-to-br from-purple-500 to-pink-600 p-3 rounded-xl shadow-md group-hover:scale-110 transition-transform">
                <Shield className="w-6 h-6 text-white" />
              </div>
              <Crown className="w-5 h-5 text-gray-300" />
            </div>
            <p className="text-gray-500 text-xs font-bold uppercase tracking-wider mb-2">Total Managers</p>
            <p className="text-3xl font-bold text-gray-900">{stats?.total_managers || 0}</p>
            <div className="mt-3 flex items-center gap-2 text-xs">
              <span className="text-purple-600 font-semibold">Active</span>
              <div className="h-1 flex-1 bg-gray-100 rounded-full overflow-hidden">
                <div className="h-full bg-gradient-to-r from-purple-500 to-pink-600 w-4/5"></div>
              </div>
            </div>
          </div>

          <div className="bg-white rounded-2xl p-6 border border-gray-100 hover:shadow-[0_8px_30px_rgb(0,0,0,0.08)] transition-all group">
            <div className="flex items-center justify-between mb-4">
              <div className="bg-gradient-to-br from-emerald-500 to-teal-600 p-3 rounded-xl shadow-md group-hover:scale-110 transition-transform">
                <PhoneCall className="w-6 h-6 text-white" />
              </div>
              <CheckCircle2 className="w-5 h-5 text-gray-300" />
            </div>
            <p className="text-gray-500 text-xs font-bold uppercase tracking-wider mb-2">Connected Calls</p>
            <p className="text-3xl font-bold text-gray-900">{stats?.connected_calls || 0}</p>
            <div className="mt-3 flex items-center gap-2 text-xs">
              <span className="text-emerald-600 font-semibold">Success Rate</span>
              <div className="h-1 flex-1 bg-gray-100 rounded-full overflow-hidden">
                <div className="h-full bg-gradient-to-r from-emerald-500 to-teal-600" style={{ width: `${stats?.conversion_rate || 0}%` }}></div>
              </div>
            </div>
          </div>

          <div className="bg-white rounded-2xl p-6 border border-gray-100 hover:shadow-[0_8px_30px_rgb(0,0,0,0.08)] transition-all group">
            <div className="flex items-center justify-between mb-4">
              <div className="bg-gradient-to-br from-amber-500 to-orange-600 p-3 rounded-xl shadow-md group-hover:scale-110 transition-transform">
                <Users className="w-6 h-6 text-white" />
              </div>
              <UserCheck className="w-5 h-5 text-gray-300" />
            </div>
            <p className="text-gray-500 text-xs font-bold uppercase tracking-wider mb-2">Total Admins</p>
            <p className="text-3xl font-bold text-gray-900">{stats?.total_admins || 0}</p>
            <div className="mt-3 flex items-center gap-2 text-xs">
              <span className="text-amber-600 font-semibold">System</span>
              <div className="h-1 flex-1 bg-gray-100 rounded-full overflow-hidden">
                <div className="h-full bg-gradient-to-r from-amber-500 to-orange-600 w-full"></div>
              </div>
            </div>
          </div>
        </div>

        {/* Premium Charts Section */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 mb-8">
          {/* Call Trends Chart - Larger */}
          <div className="lg:col-span-2 bg-white rounded-2xl p-6 border border-gray-100 shadow-[0_8px_30px_rgb(0,0,0,0.04)] hover:shadow-[0_8px_40px_rgb(0,0,0,0.06)] transition-all">
            <div className="flex items-center justify-between mb-6">
              <div className="flex items-center gap-3">
                <div className="bg-gradient-to-br from-indigo-500 to-purple-600 p-2.5 rounded-xl shadow-md">
                  <BarChart3 className="w-5 h-5 text-white" />
                </div>
                <div>
                  <h3 className="text-lg font-bold text-gray-900">Call Performance Trends</h3>
                  <p className="text-xs text-gray-500">Last 7 days activity overview</p>
                </div>
              </div>
              <div className="flex items-center gap-2">
                <div className="flex items-center gap-1.5 bg-indigo-50 px-3 py-1.5 rounded-lg">
                  <div className="w-2 h-2 bg-indigo-500 rounded-full"></div>
                  <span className="text-xs font-semibold text-indigo-700">Total Calls</span>
                </div>
                <div className="flex items-center gap-1.5 bg-emerald-50 px-3 py-1.5 rounded-lg">
                  <div className="w-2 h-2 bg-emerald-500 rounded-full"></div>
                  <span className="text-xs font-semibold text-emerald-700">Connected</span>
                </div>
              </div>
            </div>
            <ResponsiveContainer width="100%" height={320}>
              <AreaChart data={stats?.call_trends || []}>
                <defs>
                  <linearGradient id="colorCalls" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#6366f1" stopOpacity={0.3} />
                    <stop offset="95%" stopColor="#6366f1" stopOpacity={0.05} />
                  </linearGradient>
                  <linearGradient id="colorConnected" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#10b981" stopOpacity={0.3} />
                    <stop offset="95%" stopColor="#10b981" stopOpacity={0.05} />
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" stroke="#f3f4f6" vertical={false} />
                <XAxis
                  dataKey="date"
                  stroke="#9ca3af"
                  style={{ fontSize: '11px', fontWeight: '600' }}
                  tickLine={false}
                  axisLine={false}
                />
                <YAxis
                  stroke="#9ca3af"
                  style={{ fontSize: '11px', fontWeight: '600' }}
                  tickLine={false}
                  axisLine={false}
                />
                <Tooltip
                  contentStyle={{
                    backgroundColor: 'white',
                    border: '1px solid #e5e7eb',
                    borderRadius: '12px',
                    boxShadow: '0 10px 25px rgba(0,0,0,0.1)',
                    padding: '12px'
                  }}
                  labelStyle={{ fontWeight: 'bold', color: '#111827' }}
                />
                <Area
                  type="monotone"
                  dataKey="calls"
                  stroke="#6366f1"
                  fillOpacity={1}
                  fill="url(#colorCalls)"
                  strokeWidth={3}
                  dot={{ fill: '#6366f1', strokeWidth: 2, r: 4 }}
                  activeDot={{ r: 6, strokeWidth: 2 }}
                />
                <Area
                  type="monotone"
                  dataKey="connected"
                  stroke="#10b981"
                  fillOpacity={1}
                  fill="url(#colorConnected)"
                  strokeWidth={3}
                  dot={{ fill: '#10b981', strokeWidth: 2, r: 4 }}
                  activeDot={{ r: 6, strokeWidth: 2 }}
                />
              </AreaChart>
            </ResponsiveContainer>
          </div>

          {/* Call Distribution Donut */}
          <div className="bg-white rounded-2xl p-6 border border-gray-100 shadow-[0_8px_30px_rgb(0,0,0,0.04)] hover:shadow-[0_8px_40px_rgb(0,0,0,0.06)] transition-all">
            <div className="flex items-center gap-3 mb-6">
              <div className="bg-gradient-to-br from-pink-500 to-rose-600 p-2.5 rounded-xl shadow-md">
                <Target className="w-5 h-5 text-white" />
              </div>
              <div>
                <h3 className="text-lg font-bold text-gray-900">Call Status</h3>
                <p className="text-xs text-gray-500">Distribution breakdown</p>
              </div>
            </div>
            <ResponsiveContainer width="100%" height={280}>
              <PieChart>
                <Pie
                  data={stats?.call_distribution || []}
                  cx="50%"
                  cy="50%"
                  innerRadius={60}
                  outerRadius={90}
                  paddingAngle={4}
                  dataKey="value"
                >
                  {(stats?.call_distribution || []).map((_, index) => (
                    <Cell
                      key={`cell-${index}`}
                      fill={COLORS[index % COLORS.length]}
                      stroke="white"
                      strokeWidth={2}
                    />
                  ))}
                </Pie>
                <Tooltip
                  contentStyle={{
                    backgroundColor: 'white',
                    border: '1px solid #e5e7eb',
                    borderRadius: '12px',
                    boxShadow: '0 10px 25px rgba(0,0,0,0.1)',
                    padding: '12px'
                  }}
                />
              </PieChart>
            </ResponsiveContainer>
            <div className="mt-4 space-y-2">
              {(stats?.call_distribution || []).slice(0, 4).map((item, index) => (
                <div key={index} className="flex items-center justify-between text-xs">
                  <div className="flex items-center gap-2">
                    <div className="w-3 h-3 rounded-full" style={{ backgroundColor: COLORS[index % COLORS.length] }}></div>
                    <span className="text-gray-700 font-medium">{item.name}</span>
                  </div>
                  <span className="font-bold text-gray-900">{item.value}</span>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* Top Performers & Performance Radar */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 mb-8">
          {/* Top Performers Bar Chart */}
          <div className="lg:col-span-2 bg-white rounded-2xl p-6 border border-gray-100 shadow-[0_8px_30px_rgb(0,0,0,0.04)] hover:shadow-[0_8px_40px_rgb(0,0,0,0.06)] transition-all">
            <div className="flex items-center justify-between mb-6">
              <div className="flex items-center gap-3">
                <div className="bg-gradient-to-br from-amber-500 to-orange-600 p-2.5 rounded-xl shadow-md">
                  <Crown className="w-5 h-5 text-white" />
                </div>
                <div>
                  <h3 className="text-lg font-bold text-gray-900">Top Performers</h3>
                  <p className="text-xs text-gray-500">Leaderboard rankings</p>
                </div>
              </div>
              <div className="bg-gradient-to-r from-amber-50 to-orange-50 px-4 py-2 rounded-lg border border-amber-200/50">
                <span className="text-xs font-bold text-amber-700">Today's Best</span>
              </div>
            </div>
            <ResponsiveContainer width="100%" height={320}>
              <BarChart data={stats?.top_performers || []} layout="horizontal">
                <CartesianGrid strokeDasharray="3 3" stroke="#f3f4f6" horizontal={true} vertical={false} />
                <XAxis
                  type="number"
                  stroke="#9ca3af"
                  style={{ fontSize: '11px', fontWeight: '600' }}
                  tickLine={false}
                  axisLine={false}
                />
                <YAxis
                  type="category"
                  dataKey="name"
                  stroke="#9ca3af"
                  style={{ fontSize: '11px', fontWeight: '600' }}
                  tickLine={false}
                  axisLine={false}
                  width={100}
                />
                <Tooltip
                  contentStyle={{
                    backgroundColor: 'white',
                    border: '1px solid #e5e7eb',
                    borderRadius: '12px',
                    boxShadow: '0 10px 25px rgba(0,0,0,0.1)',
                    padding: '12px'
                  }}
                  cursor={{ fill: 'rgba(99, 102, 241, 0.05)' }}
                />
                <Legend />
                <Bar dataKey="calls" fill="#6366f1" radius={[0, 8, 8, 0]} name="Total Calls" />
                <Bar dataKey="connected" fill="#10b981" radius={[0, 8, 8, 0]} name="Connected" />
              </BarChart>
            </ResponsiveContainer>
          </div>

          {/* Performance Metrics Radar */}
          <div className="bg-white rounded-2xl p-6 border border-gray-100 shadow-[0_8px_30px_rgb(0,0,0,0.04)] hover:shadow-[0_8px_40px_rgb(0,0,0,0.06)] transition-all">
            <div className="flex items-center gap-3 mb-6">
              <div className="bg-gradient-to-br from-violet-500 to-purple-600 p-2.5 rounded-xl shadow-md">
                <Activity className="w-5 h-5 text-white" />
              </div>
              <div>
                <h3 className="text-lg font-bold text-gray-900">Performance</h3>
                <p className="text-xs text-gray-500">Key metrics radar</p>
              </div>
            </div>
            <ResponsiveContainer width="100%" height={280}>
              <RadarChart data={[
                { metric: 'Calls', value: Math.min(100, ((stats?.total_calls || 0) / 10)) },
                { metric: 'Connected', value: Math.min(100, ((stats?.connected_calls || 0) / 5)) },
                { metric: 'Today', value: Math.min(100, ((stats?.calls_today || 0) / 3)) },
                { metric: 'Active', value: Math.min(100, ((stats?.active_calls || 0) / 2) * 10) },
                { metric: 'Rate', value: stats?.conversion_rate || 0 },
              ]}>
                <PolarGrid stroke="#e5e7eb" />
                <PolarAngleAxis
                  dataKey="metric"
                  style={{ fontSize: '11px', fontWeight: '600', fill: '#6b7280' }}
                />
                <PolarRadiusAxis
                  angle={90}
                  domain={[0, 100]}
                  style={{ fontSize: '10px', fill: '#9ca3af' }}
                />
                <Radar
                  name="Performance"
                  dataKey="value"
                  stroke="#8b5cf6"
                  fill="#8b5cf6"
                  fillOpacity={0.6}
                  strokeWidth={2}
                />
                <Tooltip
                  contentStyle={{
                    backgroundColor: 'white',
                    border: '1px solid #e5e7eb',
                    borderRadius: '12px',
                    boxShadow: '0 10px 25px rgba(0,0,0,0.1)',
                    padding: '12px'
                  }}
                />
              </RadarChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Recent Activity & Quick Stats */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 mb-8">
          {/* Recent Activity Feed */}
          <div className="lg:col-span-2 bg-white rounded-2xl p-6 border border-gray-100 shadow-[0_8px_30px_rgb(0,0,0,0.04)]">
            <div className="flex items-center justify-between mb-6">
              <div className="flex items-center gap-3">
                <div className="bg-gradient-to-br from-blue-500 to-cyan-600 p-2.5 rounded-xl shadow-md">
                  <Activity className="w-5 h-5 text-white" />
                </div>
                <div>
                  <h3 className="text-lg font-bold text-gray-900">Recent Activity</h3>
                  <p className="text-xs text-gray-500">Live call updates</p>
                </div>
              </div>
              <div className="flex items-center gap-2 bg-blue-50 px-3 py-1.5 rounded-lg">
                <div className="w-2 h-2 bg-blue-500 rounded-full animate-pulse"></div>
                <span className="text-xs font-semibold text-blue-700">Live</span>
              </div>
            </div>
            <div className="space-y-2 max-h-[400px] overflow-y-auto custom-scrollbar">
              {(stats?.recent_activity || []).map((activity, index) => {
                const isConnected = activity.action.includes('Connected');
                const isMissed = activity.action.includes('Missed') || activity.action.includes('not_answered');
                const isPending = activity.action.includes('Pending') || activity.action.includes('pending');

                return (
                  <div key={index} className="bg-gray-50 rounded-xl p-4 border border-gray-100 hover:bg-white hover:shadow-md hover:border-gray-200 transition-all group">
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-3 flex-1">
                        <div className={`w-10 h-10 rounded-xl flex items-center justify-center shadow-sm group-hover:scale-110 transition-transform ${isConnected ? 'bg-gradient-to-br from-emerald-500 to-teal-600' :
                          isMissed ? 'bg-gradient-to-br from-red-500 to-rose-600' :
                            isPending ? 'bg-gradient-to-br from-amber-500 to-orange-600' :
                              'bg-gradient-to-br from-indigo-500 to-purple-600'
                          }`}>
                          {isConnected ? <CheckCircle2 className="w-5 h-5 text-white" /> :
                            isMissed ? <XCircle className="w-5 h-5 text-white" /> :
                              isPending ? <Timer className="w-5 h-5 text-white" /> :
                                <PhoneIncoming className="w-5 h-5 text-white" />}
                        </div>
                        <div className="flex-1 min-w-0">
                          <p className="font-bold text-gray-900 text-sm truncate">{activity.telecaller}</p>
                          <p className="text-xs text-gray-600 truncate">{activity.action}</p>
                        </div>
                      </div>
                      <div className="flex items-center gap-2 ml-3">
                        <span className="text-xs text-gray-500 bg-white px-3 py-1.5 rounded-lg font-medium border border-gray-200 whitespace-nowrap">
                          {activity.time}
                        </span>
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>
          </div>

          {/* Quick Stats Summary */}
          <div className="space-y-4">
            {/* Call Success Rate */}
            <div className="bg-gradient-to-br from-emerald-500 to-teal-600 rounded-2xl p-6 text-white shadow-lg hover:shadow-xl transition-all">
              <div className="flex items-center justify-between mb-4">
                <div className="bg-white/20 backdrop-blur-xl p-2.5 rounded-xl">
                  <Target className="w-6 h-6 text-white" />
                </div>
                <TrendingUp className="w-5 h-5 text-white/70" />
              </div>
              <p className="text-white/80 text-xs font-bold uppercase tracking-wider mb-2">Success Rate</p>
              <p className="text-4xl font-bold mb-3">{stats?.conversion_rate || 0}%</p>
              <div className="bg-white/20 rounded-full h-2 overflow-hidden">
                <div
                  className="bg-white h-full rounded-full transition-all duration-1000"
                  style={{ width: `${stats?.conversion_rate || 0}%` }}
                ></div>
              </div>
            </div>

            {/* Total Calls Summary */}
            <div className="bg-white rounded-2xl p-6 border border-gray-100 shadow-[0_8px_30px_rgb(0,0,0,0.04)]">
              <div className="flex items-center gap-3 mb-4">
                <div className="bg-gradient-to-br from-indigo-500 to-purple-600 p-2.5 rounded-xl">
                  <Phone className="w-5 h-5 text-white" />
                </div>
                <div>
                  <p className="text-xs text-gray-500 font-bold uppercase tracking-wider">Total Calls</p>
                  <p className="text-2xl font-bold text-gray-900">{stats?.total_calls || 0}</p>
                </div>
              </div>
              <div className="space-y-2">
                <div className="flex items-center justify-between text-xs">
                  <span className="text-gray-600 flex items-center gap-2">
                    <CheckCircle2 className="w-3.5 h-3.5 text-emerald-500" />
                    Connected
                  </span>
                  <span className="font-bold text-gray-900">{stats?.connected_calls || 0}</span>
                </div>
                <div className="flex items-center justify-between text-xs">
                  <span className="text-gray-600 flex items-center gap-2">
                    <Timer className="w-3.5 h-3.5 text-amber-500" />
                    Active
                  </span>
                  <span className="font-bold text-gray-900">{stats?.active_calls || 0}</span>
                </div>
                <div className="flex items-center justify-between text-xs">
                  <span className="text-gray-600 flex items-center gap-2">
                    <Calendar className="w-3.5 h-3.5 text-blue-500" />
                    Today
                  </span>
                  <span className="font-bold text-gray-900">{stats?.calls_today || 0}</span>
                </div>
              </div>
            </div>

            {/* Team Summary */}
            <div className="bg-gradient-to-br from-violet-500 to-purple-600 rounded-2xl p-6 text-white shadow-lg hover:shadow-xl transition-all">
              <div className="flex items-center gap-3 mb-4">
                <div className="bg-white/20 backdrop-blur-xl p-2.5 rounded-xl">
                  <Users className="w-6 h-6 text-white" />
                </div>
                <div>
                  <p className="text-white/80 text-xs font-bold uppercase tracking-wider">Team Size</p>
                  <p className="text-2xl font-bold">{(stats?.total_telecallers || 0) + (stats?.total_managers || 0)}</p>
                </div>
              </div>
              <div className="grid grid-cols-2 gap-3">
                <div className="bg-white/10 backdrop-blur-xl rounded-lg p-3">
                  <p className="text-white/70 text-xs mb-1">Telecallers</p>
                  <p className="text-xl font-bold">{stats?.total_telecallers || 0}</p>
                </div>
                <div className="bg-white/10 backdrop-blur-xl rounded-lg p-3">
                  <p className="text-white/70 text-xs mb-1">Managers</p>
                  <p className="text-xl font-bold">{stats?.total_managers || 0}</p>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* System Status Footer */}
        <div className="bg-white rounded-2xl p-6 border border-gray-100 shadow-[0_8px_30px_rgb(0,0,0,0.04)]">
          <div className="flex items-center justify-between flex-wrap gap-4">
            <div className="flex items-center gap-6">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 bg-gradient-to-br from-emerald-500 to-teal-600 rounded-xl flex items-center justify-center">
                  <CheckCircle2 className="w-5 h-5 text-white" />
                </div>
                <div>
                  <p className="text-xs text-gray-500 font-semibold">System Status</p>
                  <p className="text-sm font-bold text-gray-900">All Systems Operational</p>
                </div>
              </div>
              <div className="h-8 w-px bg-gray-200"></div>
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 bg-gradient-to-br from-blue-500 to-cyan-600 rounded-xl flex items-center justify-center">
                  <Activity className="w-5 h-5 text-white" />
                </div>
                <div>
                  <p className="text-xs text-gray-500 font-semibold">Database</p>
                  <p className="text-sm font-bold text-gray-900">Connected</p>
                </div>
              </div>
              <div className="h-8 w-px bg-gray-200"></div>
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 bg-gradient-to-br from-purple-500 to-pink-600 rounded-xl flex items-center justify-center">
                  <Zap className="w-5 h-5 text-white" />
                </div>
                <div>
                  <p className="text-xs text-gray-500 font-semibold">API Response</p>
                  <p className="text-sm font-bold text-gray-900">Fast</p>
                </div>
              </div>
            </div>
            <div className="text-xs text-gray-500">
              Last updated: <span className="font-semibold text-gray-700">{new Date().toLocaleTimeString()}</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Dashboard;
