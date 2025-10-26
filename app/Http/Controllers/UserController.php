<?php
namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Session;

class UserController extends Controller
{
    // View all users with pagination
    public function index()
    {
		 if (Session::get('role') != 'admin') {
            return redirect('admin');
        }

		
        $users = User::with('subscription')->paginate(10); // 10 users per page
        return view('Admin.users.index', compact('users'));
    }

    // View specific user details
    public function show($id)
    {
        $user = User::findOrFail($id);
        return view('Admin.users.show', compact('user'));
    }
}
