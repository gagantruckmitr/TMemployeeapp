import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import axios from 'axios';
import { API_BASE_URL } from '../config/api';
import { 
  Plus, Search, Edit, Trash2, Users, Shield, Crown, Target, 
  TrendingUp, Activity, Zap, Phone, CheckCircle2, Clock, Award,
  UserCheck, ArrowUpRight, Eye, XCircle, BarChart3, Calendar, Briefcase
} from 'lucide-react';
import ManagerModal from '../components/ManagerModal';
import { LineChart, Line, ResponsiveContainer, Tooltip } from 'recharts';

const Managers = () => {
  const [searchTerm, setSearchTerm] = useState('');
  const [modalOpen, setModalOpen] = useState(false);
  const [selectedManager, setSelectedManager] = useState(null);
  const [selectedForDetails, setSelectedForDetails] = useState(null);
  const queryClient = useQueryClient();

  const { data: managersData, isLoading } = useQuery({
    queryKey: ['managers-detailed'],
    queryFn: async () => {
      const response = await axios.get(`${API_BASE_URL}/admin_managers_detailed_api.php`);
      return response.data;
    },
    refetchInterval: 30000,
  });

  const managers = managersData?.data || [];

  const deleteMutation = useMutation({
    mutationFn: async (id) => {
      await axios.delete(`${API_BASE_URL}/admin_managers_detailed_api.php?id=${id}`);
    },
    onSuccess: () => {
      queryClient.invalidateQueries(['managers-detailed']);
    },
  });

  const filteredManagers = managers?.filter(m =>
    m.name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    m.email?.toLowerCase().includes(searchTerm.toLowerCase())
  ) || [];

  const handleEdit = (manager) => {
    setSelectedManager(manager);
    setModalOpen(true);
  };

  const handleDelete = (id) => {
    if (window.confirm('Are you sure you want to delete this manager?')) {
      deleteMutation.mutate(id);
    }
  };

  // Calculate summary stats
  const summary = {
    totalManagers: managers.length,
    activeManagers: managers.filter(m => m.status === 'active').length,
    totalTeamSize: managers.reduce((sum, m) => sum + m.team_size, 0),
    totalTeamCalls: managers.reduce((sum, m) => sum + m.team_total_calls, 0),
    avgConversionRate: managers.length > 0 
      ? (managers.reduce((sum, m) => sum + m.team_conversion_rate, 0) / managers.length).toFixed(1)
      : 0
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-50 via-white to-gray-50 p-6">
      {/* Background Pattern */}
      <div className="fixed inset-0 bg-[radial-gradient(circle_at_20%_30%,rgba(139,92,246,0.03),transparent_40%),radial-gradient(circle_at_80%_70%,rgba(236,72,153,0.03),transparent_40%)] pointer-events-none"></div>
      <div className="fixed inset-0 bg-[linear-gradient(to_right,#80808008_1px,transparent_1px),linear-gradient(to_bottom,#80808008_1px,transparent_1px)] bg-[size:64px_64px] pointer-events-none"></div>

      <div className="relative z-10 max-w-[1800px] mx-auto space-y-6">
        {/* Premium Header */}
        <div className="bg-white rounded-3xl p-8 border border-gray-100 shadow-[0_8px_30px_rgb(0,0,0,0.04)]">
          <div className="flex items-center justify-between flex-wrap gap-4">
            <div className="flex items-center gap-4">
              <div className="relative">
                <div className="absolute inset-0 bg-gradient-to-br from-purple-500 to-pink-600 rounded-2xl blur-xl opacity-30 animate-pulse"></div>
                <div className="relative bg-gradient-to-br from-purple-500 to-pink-600 p-3.5 rounded-2xl shadow-lg">
                  <Crown className="w-9 h-9 text-white" />
                </div>
              </div>
              <div>
                <h1 className="text-4xl font-bold bg-gradient-to-r from-gray-900 via-gray-800 to-gray-900 bg-clip-text text-transparent mb-1">
                  Manager Management
                </h1>
                <p className="text-gray-500 text-base font-medium">Team leaders & performance oversight</p>
              </div>
            </div>
            <button
              onClick={() => {
                setSelectedManager(null);
                setModalOpen(true);
              }}
              className="flex items-center gap-2 px-6 py-3 bg-gradient-to-r from-purple-600 to-pink-600 text-white rounded-xl hover:from-purple-700 hover:to-pink-700 transition-all shadow-lg hover:shadow-xl hover:scale-105"
            >
              <Plus className="w-5 h-5" />
              <span className="font-semibold">Add Manager</span>
            </button>
          </div>
        </div>

        {/* Summary Cards */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-6">
          <div className="bg-white rounded-2xl p-6 border border-gray-100 shadow-[0_8px_30px_rgb(0,0,0,0.04)] hover:shadow-[0_8px_40px_rgb(0,0,0,0.06)] transition-all">
            <div className="flex items-center justify-between mb-4">
              <div className="bg-gradient-to-br from-purple-500 to-pink-600 p-3 rounded-xl shadow-md">
                <Crown className="w-6 h-6 text-white" />
              </div>
              <div className="flex items-center gap-1.5 bg-purple-50 text-purple-600 px-3 py-1.5 rounded-full border border-purple-200/50">
                <ArrowUpRight className="w-3.5 h-3.5" />
                <span className="text-xs font-bold">{summary.activeManagers}/{summary.totalManagers}</span>
              </div>
            </div>
            <p className="text-gray-500 text-xs font-bold uppercase tracking-wider mb-2">Total Managers</p>
            <p className="text-3xl font-bold text-gray-900">{summary.totalManagers}</p>
            <p className="text-xs text-gray-500 mt-2">{summary.activeManagers} active now</p>
          </div>

          <div className="bg-white rounded-2xl p-6 border border-gray-100 shadow-[0_8px_30px_rgb(0,0,0,0.04)] hover:shadow-[0_8px_40px_rgb(0,0,0,0.06)] transition-all">
            <div className="flex items-center justify-between mb-4">
              <div className="bg-gradient-to-br from-indigo-500 to-blue-600 p-3 rounded-xl shadow-md">
                <Users className="w-6 h-6 text-white" />
              </div>
              <UserCheck className="w-5 h-5 text-indigo-500" />
            </div>
            <p className="text-gray-500 text-xs font-bold uppercase tracking-wider mb-2">Total Team Size</p>
            <p className="text-3xl font-bold text-gray-900">{summary.totalTeamSize}</p>
            <p className="text-xs text-gray-500 mt-2">Telecallers managed</p>
          </div>

          <div className="bg-white rounded-2xl p-6 border border-gray-100 shadow-[0_8px_30px_rgb(0,0,0,0.04)] hover:shadow-[0_8px_40px_rgb(0,0,0,0.06)] transition-all">
            <div className="flex items-center justify-between mb-4">
              <div className="bg-gradient-to-br from-emerald-500 to-teal-600 p-3 rounded-xl shadow-md">
                <Phone className="w-6 h-6 text-white" />
              </div>
              <CheckCircle2 className="w-5 h-5 text-emerald-500" />
            </div>
            <p className="text-gray-500 text-xs font-bold uppercase tracking-wider mb-2">Team Calls</p>
            <p className="text-3xl font-bold text-gray-900">{summary.totalTeamCalls}</p>
            <p className="text-xs text-gray-500 mt-2">Total by all teams</p>
          </div>

          <div className="bg-white rounded-2xl p-6 border border-gray-100 shadow-[0_8px_30px_rgb(0,0,0,0.04)] hover:shadow-[0_8px_40px_rgb(0,0,0,0.06)] transition-all">
            <div className="flex items-center justify-between mb-4">
              <div className="bg-gradient-to-br from-amber-500 to-orange-600 p-3 rounded-xl shadow-md">
                <Target className="w-6 h-6 text-white" />
              </div>
              <TrendingUp className="w-5 h-5 text-amber-500" />
            </div>
            <p className="text-gray-500 text-xs font-bold uppercase tracking-wider mb-2">Avg Conversion</p>
            <p className="text-3xl font-bold text-gray-900">{summary.avgConversionRate}%</p>
            <p className="text-xs text-gray-500 mt-2">Team average rate</p>
          </div>

          <div className="bg-gradient-to-br from-purple-500 to-pink-600 rounded-2xl p-6 text-white shadow-lg hover:shadow-xl transition-all">
            <div className="flex items-center justify-between mb-4">
              <div className="bg-white/20 backdrop-blur-xl p-3 rounded-xl">
                <Award className="w-6 h-6 text-white" />
              </div>
              <Zap className="w-5 h-5 text-white/70" />
            </div>
            <p className="text-white/80 text-xs font-bold uppercase tracking-wider mb-2">Performance</p>
            <p className="text-3xl font-bold">Excellent</p>
            <p className="text-xs text-white/70 mt-2">Overall rating</p>
          </div>
        </div>

        {/* Search Bar */}
        <div className="bg-white rounded-2xl p-4 border border-gray-100 shadow-[0_8px_30px_rgb(0,0,0,0.04)]">
          <div className="relative">
            <Search className="absolute left-4 top-1/2 transform -translate-y-1/2 text-gray-400 w-5 h-5" />
            <input
              type="text"
              placeholder="Search managers by name or email..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full pl-12 pr-4 py-3 border border-gray-200 rounded-xl focus:ring-2 focus:ring-purple-500 focus:border-transparent transition-all"
            />
          </div>
        </div>

        {/* Managers Grid */}
        {isLoading ? (
          <div className="flex items-center justify-center h-64 bg-white rounded-2xl border border-gray-100">
            <div className="relative">
              <div className="w-20 h-20 border-4 border-purple-500 border-t-transparent rounded-full animate-spin"></div>
              <div className="absolute top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2">
                <Zap className="w-8 h-8 text-purple-500 animate-pulse" />
              </div>
            </div>
          </div>
        ) : filteredManagers.length === 0 ? (
          <div className="bg-white rounded-2xl p-12 text-center border border-gray-100">
            <Crown className="w-16 h-16 text-gray-300 mx-auto mb-4" />
            <h3 className="text-xl font-bold text-gray-900 mb-2">No Managers Found</h3>
            <p className="text-gray-500 mb-6">
              {searchTerm ? 'Try adjusting your search terms' : 'Get started by adding your first manager'}
            </p>
            {!searchTerm && (
              <button
                onClick={() => {
                  setSelectedManager(null);
                  setModalOpen(true);
                }}
                className="inline-flex items-center gap-2 px-6 py-3 bg-gradient-to-r from-purple-600 to-pink-600 text-white rounded-xl hover:from-purple-700 hover:to-pink-700 transition-all shadow-lg"
              >
                <Plus className="w-5 h-5" />
                Add First Manager
              </button>
            )}
          </div>
        ) : (
          <div className="grid grid-cols-1 lg:grid-cols-2 xl:grid-cols-3 gap-6">
            {filteredManagers.map((manager) => {
              const statusConfig = {
                active: { bg: 'bg-emerald-50', text: 'text-emerald-700', border: 'border-emerald-200', dot: 'bg-emerald-500' },
                idle: { bg: 'bg-amber-50', text: 'text-amber-700', border: 'border-amber-200', dot: 'bg-amber-500' },
                inactive: { bg: 'bg-gray-50', text: 'text-gray-700', border: 'border-gray-200', dot: 'bg-gray-500' }
              };
              const status = statusConfig[manager.status] || statusConfig.inactive;

              return (
                <div 
                  key={manager.id} 
                  className="bg-white rounded-2xl border border-gray-100 shadow-[0_8px_30px_rgb(0,0,0,0.04)] hover:shadow-[0_8px_40px_rgb(0,0,0,0.06)] transition-all overflow-hidden group"
                >
                  {/* Header */}
                  <div className="p-6 pb-4">
                    <div className="flex items-start justify-between mb-4">
                      <div className="flex items-center gap-3">
                        <div className="relative">
                          <div className="w-14 h-14 bg-gradient-to-br from-purple-500 to-pink-600 rounded-xl flex items-center justify-center shadow-lg group-hover:scale-110 transition-transform">
                            <span className="text-white font-bold text-xl">
                              {manager.name?.charAt(0)?.toUpperCase() || 'M'}
                            </span>
                          </div>
                          <div className={`absolute -bottom-1 -right-1 w-4 h-4 ${status.dot} rounded-full border-2 border-white`}></div>
                        </div>
                        <div>
                          <h3 className="font-bold text-gray-900 text-lg">{manager.name}</h3>
                          <div className={`inline-flex items-center gap-1.5 ${status.bg} ${status.text} px-2.5 py-1 rounded-lg border ${status.border} text-xs font-semibold mt-1`}>
                            <div className={`w-1.5 h-1.5 ${status.dot} rounded-full animate-pulse`}></div>
                            {manager.status}
                          </div>
                        </div>
                      </div>
                      <div className="flex gap-1">
                        <button
                          onClick={() => setSelectedForDetails(manager)}
                          className="p-2 text-purple-600 hover:bg-purple-50 rounded-lg transition-colors"
                          title="View Details"
                        >
                          <Eye className="w-4 h-4" />
                        </button>
                        <button
                          onClick={() => handleEdit(manager)}
                          className="p-2 text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"
                          title="Edit"
                        >
                          <Edit className="w-4 h-4" />
                        </button>
                        <button
                          onClick={() => handleDelete(manager.id)}
                          className="p-2 text-red-600 hover:bg-red-50 rounded-lg transition-colors"
                          title="Delete"
                        >
                          <Trash2 className="w-4 h-4" />
                        </button>
                      </div>
                    </div>

                    {/* Contact Info */}
                    <div className="space-y-2 mb-4">
                      <div className="flex items-center text-sm text-gray-600">
                        <Phone className="w-4 h-4 mr-2 text-gray-400" />
                        <span className="font-medium">{manager.phone || 'N/A'}</span>
                      </div>
                      <div className="flex items-center text-sm text-gray-600">
                        <Shield className="w-4 h-4 mr-2 text-gray-400" />
                        <span className="font-medium truncate">{manager.email || 'N/A'}</span>
                      </div>
                      <div className="flex items-center text-sm text-gray-600">
                        <Clock className="w-4 h-4 mr-2 text-gray-400" />
                        <span className="font-medium">Last activity: {manager.last_activity_formatted}</span>
                      </div>
                    </div>

                    {/* Mini Trend Chart */}
                    {manager.performance_trend && manager.performance_trend.length > 0 && (
                      <div className="mb-4">
                        <ResponsiveContainer width="100%" height={60}>
                          <LineChart data={manager.performance_trend}>
                            <Line 
                              type="monotone" 
                              dataKey="calls" 
                              stroke="#a855f7" 
                              strokeWidth={2}
                              dot={false}
                            />
                            <Line 
                              type="monotone" 
                              dataKey="connected" 
                              stroke="#10b981" 
                              strokeWidth={2}
                              dot={false}
                            />
                            <Tooltip 
                              contentStyle={{
                                backgroundColor: 'white',
                                border: '1px solid #e5e7eb',
                                borderRadius: '8px',
                                fontSize: '12px'
                              }}
                            />
                          </LineChart>
                        </ResponsiveContainer>
                        <p className="text-xs text-gray-500 text-center mt-1">7-day team trend</p>
                      </div>
                    )}
                  </div>

                  {/* Stats Grid */}
                  <div className="bg-gray-50 px-6 py-4 border-t border-gray-100">
                    <div className="grid grid-cols-3 gap-4 mb-3">
                      <div className="text-center">
                        <div className="flex items-center justify-center gap-1 mb-1">
                          <Users className="w-3.5 h-3.5 text-purple-500" />
                          <p className="text-xl font-bold text-gray-900">{manager.team_size}</p>
                        </div>
                        <p className="text-xs text-gray-600 font-medium">Team Size</p>
                      </div>
                      <div className="text-center">
                        <div className="flex items-center justify-center gap-1 mb-1">
                          <Phone className="w-3.5 h-3.5 text-emerald-500" />
                          <p className="text-xl font-bold text-gray-900">{manager.team_total_calls}</p>
                        </div>
                        <p className="text-xs text-gray-600 font-medium">Total Calls</p>
                      </div>
                      <div className="text-center">
                        <div className="flex items-center justify-center gap-1 mb-1">
                          <Target className="w-3.5 h-3.5 text-blue-500" />
                          <p className="text-xl font-bold text-blue-600">{manager.team_conversion_rate}%</p>
                        </div>
                        <p className="text-xs text-gray-600 font-medium">Conv. Rate</p>
                      </div>
                    </div>

                    <div className="grid grid-cols-2 gap-3 pt-3 border-t border-gray-200">
                      <div className="bg-white rounded-lg p-2.5 border border-gray-100">
                        <div className="flex items-center justify-between mb-1">
                          <span className="text-xs text-gray-600 font-medium">Active</span>
                          <UserCheck className="w-3.5 h-3.5 text-gray-400" />
                        </div>
                        <p className="text-lg font-bold text-gray-900">{manager.active_telecallers}</p>
                      </div>
                      <div className="bg-white rounded-lg p-2.5 border border-gray-100">
                        <div className="flex items-center justify-between mb-1">
                          <span className="text-xs text-gray-600 font-medium">Connected</span>
                          <CheckCircle2 className="w-3.5 h-3.5 text-gray-400" />
                        </div>
                        <p className="text-lg font-bold text-gray-900">{manager.team_connected_calls}</p>
                      </div>
                    </div>

                    {/* Quick Stats */}
                    <div className="mt-3 pt-3 border-t border-gray-200 grid grid-cols-3 gap-2 text-xs">
                      <div className="text-center">
                        <p className="text-gray-500 mb-0.5">Today</p>
                        <p className="font-bold text-gray-900">{manager.team_calls_today}</p>
                      </div>
                      <div className="text-center">
                        <p className="text-gray-500 mb-0.5">Week</p>
                        <p className="font-bold text-gray-900">{manager.team_calls_this_week}</p>
                      </div>
                      <div className="text-center">
                        <p className="text-gray-500 mb-0.5">Month</p>
                        <p className="font-bold text-gray-900">{manager.team_calls_this_month}</p>
                      </div>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        )}

        {/* Detailed View Modal */}
        {selectedForDetails && (
          <div className="fixed inset-0 bg-black/50 backdrop-blur-sm z-50 flex items-start justify-center p-4 overflow-y-auto">
            <div className="bg-white rounded-3xl max-w-5xl w-full my-4 shadow-2xl max-h-[95vh] flex flex-col">
              {/* Modal Header */}
              <div className="flex-shrink-0 bg-white border-b border-gray-100 p-5 rounded-t-3xl">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <div className="w-14 h-14 bg-gradient-to-br from-purple-500 to-pink-600 rounded-xl flex items-center justify-center shadow-lg">
                      <span className="text-white font-bold text-xl">
                        {selectedForDetails.name?.charAt(0)?.toUpperCase()}
                      </span>
                    </div>
                    <div>
                      <h2 className="text-xl font-bold text-gray-900">{selectedForDetails.name}</h2>
                      <p className="text-sm text-gray-500">{selectedForDetails.email}</p>
                    </div>
                  </div>
                  <button
                    onClick={() => setSelectedForDetails(null)}
                    className="p-2 hover:bg-gray-100 rounded-xl transition-colors flex-shrink-0"
                  >
                    <XCircle className="w-5 h-5 text-gray-500" />
                  </button>
                </div>
              </div>

              {/* Modal Content */}
              <div className="flex-1 overflow-y-auto custom-scrollbar p-5 space-y-5">
                {/* Team Overview */}
                <div>
                  <h3 className="text-base font-bold text-gray-900 mb-3 flex items-center gap-2">
                    <Users className="w-4 h-4 text-purple-600" />
                    Team Overview
                  </h3>
                  <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
                    <div className="bg-gradient-to-br from-purple-50 to-pink-50 rounded-xl p-3 border border-purple-100">
                      <Users className="w-6 h-6 text-purple-600 mb-1" />
                      <p className="text-2xl font-bold text-gray-900">{selectedForDetails.team_size}</p>
                      <p className="text-xs text-gray-600 font-medium">Team Size</p>
                    </div>
                    <div className="bg-gradient-to-br from-emerald-50 to-teal-50 rounded-xl p-3 border border-emerald-100">
                      <UserCheck className="w-6 h-6 text-emerald-600 mb-1" />
                      <p className="text-2xl font-bold text-gray-900">{selectedForDetails.active_telecallers}</p>
                      <p className="text-xs text-gray-600 font-medium">Active Now</p>
                    </div>
                    <div className="bg-gradient-to-br from-blue-50 to-cyan-50 rounded-xl p-3 border border-blue-100">
                      <Phone className="w-6 h-6 text-blue-600 mb-1" />
                      <p className="text-2xl font-bold text-gray-900">{selectedForDetails.team_total_calls}</p>
                      <p className="text-xs text-gray-600 font-medium">Total Calls</p>
                    </div>
                    <div className="bg-gradient-to-br from-amber-50 to-orange-50 rounded-xl p-3 border border-amber-100">
                      <Target className="w-6 h-6 text-amber-600 mb-1" />
                      <p className="text-2xl font-bold text-gray-900">{selectedForDetails.team_conversion_rate}%</p>
                      <p className="text-xs text-gray-600 font-medium">Conv. Rate</p>
                    </div>
                  </div>
                </div>

                {/* Time-based Stats */}
                <div>
                  <h3 className="text-base font-bold text-gray-900 mb-3 flex items-center gap-2">
                    <Calendar className="w-4 h-4 text-blue-600" />
                    Team Performance Timeline
                  </h3>
                  <div className="grid grid-cols-3 gap-3">
                    <div className="bg-white rounded-xl p-3 border border-gray-100 shadow-sm">
                      <div className="flex items-center justify-between mb-1">
                        <span className="text-xs text-gray-600 font-medium">Today</span>
                        <Activity className="w-4 h-4 text-blue-500" />
                      </div>
                      <p className="text-xl font-bold text-gray-900">{selectedForDetails.team_calls_today}</p>
                      <p className="text-xs text-gray-500">calls made</p>
                    </div>
                    <div className="bg-white rounded-xl p-3 border border-gray-100 shadow-sm">
                      <div className="flex items-center justify-between mb-1">
                        <span className="text-xs text-gray-600 font-medium">This Week</span>
                        <Calendar className="w-4 h-4 text-purple-500" />
                      </div>
                      <p className="text-xl font-bold text-gray-900">{selectedForDetails.team_calls_this_week}</p>
                      <p className="text-xs text-gray-500">calls made</p>
                    </div>
                    <div className="bg-white rounded-xl p-3 border border-gray-100 shadow-sm">
                      <div className="flex items-center justify-between mb-1">
                        <span className="text-xs text-gray-600 font-medium">This Month</span>
                        <BarChart3 className="w-4 h-4 text-indigo-500" />
                      </div>
                      <p className="text-xl font-bold text-gray-900">{selectedForDetails.team_calls_this_month}</p>
                      <p className="text-xs text-gray-500">calls made</p>
                    </div>
                  </div>
                </div>

                {/* Team Members */}
                <div>
                  <h3 className="text-base font-bold text-gray-900 mb-3 flex items-center gap-2">
                    <Briefcase className="w-4 h-4 text-emerald-600" />
                    Team Members ({selectedForDetails.team_members?.length || 0})
                  </h3>
                  <div className="bg-gray-50 rounded-xl p-4 max-h-64 overflow-y-auto custom-scrollbar">
                    {selectedForDetails.team_members && selectedForDetails.team_members.length > 0 ? (
                      <div className="space-y-2">
                        {selectedForDetails.team_members.map((member, index) => (
                          <div key={index} className="bg-white rounded-lg p-3 border border-gray-100 flex items-center justify-between">
                            <div className="flex items-center gap-3">
                              <div className="w-10 h-10 bg-gradient-to-br from-indigo-500 to-purple-600 rounded-lg flex items-center justify-center">
                                <span className="text-white font-bold text-sm">
                                  {member.name?.charAt(0)?.toUpperCase()}
                                </span>
                              </div>
                              <div>
                                <p className="font-semibold text-gray-900 text-sm">{member.name}</p>
                                <p className="text-xs text-gray-500">{member.email}</p>
                              </div>
                            </div>
                            <div className="text-right">
                              <p className="text-sm font-bold text-gray-900">{member.total_calls}</p>
                              <p className="text-xs text-gray-500">calls</p>
                            </div>
                          </div>
                        ))}
                      </div>
                    ) : (
                      <p className="text-center text-gray-500 py-4">No team members assigned</p>
                    )}
                  </div>
                </div>

                {/* Activity Info */}
                <div>
                  <h3 className="text-base font-bold text-gray-900 mb-3 flex items-center gap-2">
                    <Activity className="w-4 h-4 text-indigo-600" />
                    Manager Information
                  </h3>
                  <div className="bg-gray-50 rounded-xl p-3 border border-gray-100">
                    <div className="flex items-center justify-between">
                      <div>
                        <p className="text-xs text-gray-600 font-medium">Last Activity</p>
                        <p className="text-base font-bold text-gray-900">{selectedForDetails.last_activity_formatted}</p>
                      </div>
                      <div className="text-right">
                        <p className="text-xs text-gray-600 font-medium">Member Since</p>
                        <p className="text-base font-bold text-gray-900">
                          {new Date(selectedForDetails.created_at).toLocaleDateString('en-US', { 
                            month: 'short', 
                            day: 'numeric', 
                            year: 'numeric' 
                          })}
                        </p>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        )}

        {modalOpen && (
          <ManagerModal
            manager={selectedManager}
            onClose={() => {
              setModalOpen(false);
              setSelectedManager(null);
            }}
          />
        )}
      </div>
    </div>
  );
};

export default Managers;
