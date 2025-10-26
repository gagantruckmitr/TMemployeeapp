import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { Lock, User, Loader, Eye, EyeOff, ArrowRight } from 'lucide-react';
import logoImage from '/logo.png';

const Login = () => {
    const [username, setUsername] = useState('');
    const [password, setPassword] = useState('');
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');
    const [showPassword, setShowPassword] = useState(false);
    const { login } = useAuth();
    const navigate = useNavigate();

    const handleSubmit = async (e) => {
        e.preventDefault();
        setError('');
        setLoading(true);

        const result = await login(username, password);

        if (result.success) {
            navigate('/dashboard');
        } else {
            setError(result.message || 'Invalid credentials');
        }
        setLoading(false);
    };

    return (
        <div className="min-h-screen bg-white flex">
            {/* Left Side - Login Form */}
            <div className="w-full lg:w-2/5 flex items-center justify-center px-8 py-12">
                <div className="w-full max-w-md">
                    {/* Logo */}
                    <div className="mb-10">
                        <img
                            src={logoImage}
                            alt="TruckMitr Logo"
                            className="h-20 w-auto mb-8"
                            onError={(e) => {
                                e.target.style.display = 'none';
                                console.error('Logo failed to load');
                            }}
                        />
                        <h1 className="text-4xl font-bold text-gray-900 mb-3">
                            Welcome back
                        </h1>
                        <p className="text-gray-600 text-lg">
                            Sign in to access your admin dashboard
                        </p>
                    </div>

                    {/* Error Message */}
                    {error && (
                        <div className="mb-6 p-4 bg-red-50 border-l-4 border-red-500 rounded-r-lg">
                            <p className="text-red-700 text-sm font-medium">{error}</p>
                        </div>
                    )}

                    {/* Login Form */}
                    <form onSubmit={handleSubmit} className="space-y-6">
                        {/* Mobile Number Input */}
                        <div>
                            <label className="block text-sm font-semibold text-gray-700 mb-2">
                                Mobile Number
                            </label>
                            <div className="relative group">
                                <div className="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none">
                                    <User className="h-5 w-5 text-gray-400 group-focus-within:text-indigo-600 transition-colors" />
                                </div>
                                <input
                                    type="text"
                                    value={username}
                                    onChange={(e) => setUsername(e.target.value)}
                                    className="w-full pl-12 pr-4 py-3.5 bg-gray-50 border-2 border-gray-200 rounded-xl focus:bg-white focus:border-indigo-600 focus:ring-4 focus:ring-indigo-100 transition-all outline-none text-gray-900"
                                    placeholder="Enter your mobile number"
                                    required
                                />
                            </div>
                        </div>

                        {/* Password Input */}
                        <div>
                            <label className="block text-sm font-semibold text-gray-700 mb-2">
                                Password
                            </label>
                            <div className="relative group">
                                <div className="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none">
                                    <Lock className="h-5 w-5 text-gray-400 group-focus-within:text-indigo-600 transition-colors" />
                                </div>
                                <input
                                    type={showPassword ? 'text' : 'password'}
                                    value={password}
                                    onChange={(e) => setPassword(e.target.value)}
                                    className="w-full pl-12 pr-12 py-3.5 bg-gray-50 border-2 border-gray-200 rounded-xl focus:bg-white focus:border-indigo-600 focus:ring-4 focus:ring-indigo-100 transition-all outline-none text-gray-900"
                                    placeholder="Enter your password"
                                    required
                                />
                                <button
                                    type="button"
                                    onClick={() => setShowPassword(!showPassword)}
                                    className="absolute inset-y-0 right-0 pr-4 flex items-center text-gray-400 hover:text-gray-600 transition-colors"
                                >
                                    {showPassword ? (
                                        <EyeOff className="h-5 w-5" />
                                    ) : (
                                        <Eye className="h-5 w-5" />
                                    )}
                                </button>
                            </div>
                        </div>

                        {/* Remember Me & Forgot Password */}
                        <div className="flex items-center justify-between">
                            <label className="flex items-center">
                                <input
                                    type="checkbox"
                                    className="w-4 h-4 text-indigo-600 border-gray-300 rounded focus:ring-indigo-500"
                                />
                                <span className="ml-2 text-sm text-gray-600">Remember me</span>
                            </label>
                            <a href="#" className="text-sm font-semibold text-indigo-600 hover:text-indigo-700 transition-colors">
                                Forgot password?
                            </a>
                        </div>

                        {/* Submit Button */}
                        <button
                            type="submit"
                            disabled={loading}
                            className="w-full bg-gradient-to-r from-indigo-600 to-indigo-700 hover:from-indigo-700 hover:to-indigo-800 text-white py-4 rounded-xl font-semibold shadow-lg shadow-indigo-500/30 hover:shadow-xl hover:shadow-indigo-500/40 transition-all disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center group"
                        >
                            {loading ? (
                                <>
                                    <Loader className="animate-spin w-5 h-5 mr-2" />
                                    Signing in...
                                </>
                            ) : (
                                <>
                                    Sign In
                                    <ArrowRight className="ml-2 w-5 h-5 group-hover:translate-x-1 transition-transform" />
                                </>
                            )}
                        </button>
                    </form>
                </div>
            </div>

            {/* Right Side - Video Background */}
            <div className="hidden lg:block lg:w-3/5 relative overflow-hidden">
                {/* Video Background */}
                <video
                    autoPlay
                    loop
                    muted
                    playsInline
                    preload="auto"
                    style={{
                        width: '100%',
                        height: '120%',
                        objectFit: 'cover',
                        position: 'absolute',
                        top: '-10%',
                        left: '0',
                        filter: 'none'
                    }}
                >
                    <source src="http://localhost:5173/theemolyeeAdmin/Indian_Truck_Driver_Receives_Keys.mp4" type="video/mp4" />
                </video>
                <div className="absolute inset-0 bg-[#1B69B3] opacity-15"></div>
            </div>
        </div>
    );
};

export default Login;
