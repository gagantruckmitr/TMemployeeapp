<?php

namespace App\Http\Controllers;

use App\Models\Subscription;
use App\Models\User;
use Illuminate\Http\Request;
use Carbon\Carbon;
use Illuminate\Support\Facades\Session;

class SubscriptionController extends Controller
{
    // Show all subscriptions
    public function index()
    {
		 if (Session::get('role') != 'admin') {
            return redirect('admin');
        }
        $subscriptions = Subscription::with('user')->get();
		
        return view('Admin.subscriptions.index', compact('subscriptions'));
    }

    // Show form to create a new subscription
public function create()
{
	 if (Session::get('role') != 'admin') {
            return redirect('admin');
        }
    // Unique roles le lo users table se
    $roles = User::select('role')
    ->whereNotNull('role')
    ->where('role', '!=', 'Role') // remove the literal "Role"
    ->distinct()
    ->pluck('role');
    return view('Admin.subscriptions.create', compact('roles'));
}

	public function edit($id)
{
		 if (Session::get('role') != 'admin') {
            return redirect('admin');
        }
    $subscription = Subscription::findOrFail($id);
    $roles = User::select('role')
    ->whereNotNull('role')
    ->where('role', '!=', 'Role') // remove the literal "Role"
    ->distinct()
    ->pluck('role');
    return view('Admin.subscriptions.edit', compact('subscription', 'roles'));
}
    // Store a new subscription
public function store(Request $request)
{
	 if (Session::get('role') != 'admin') {
            return redirect('admin');
        }
    $request->validate([
        'role' => 'required|string|exists:users,role',
        'amount' => 'required|numeric',
        'duration' => 'required|numeric',
        'title' => 'nullable|string',
'description' => 'nullable|string',
    ]);

    // Pehla user jis role ka hai usse assign kar do
    $user = User::where('role', $request->role)->first();

    if (!$user) {
        return back()->withErrors(['role' => 'No user found for this role']);
    }

    $start = now();
    $end = now()->addMonths($request->duration);

    Subscription::create([
        'user_id' => $user->id,
        'amount' => $request->amount,
		'duration' => $request->duration,
        'title' => $request->title,
		'description' => $request->description,
        'start_at' => $start->timestamp,
        'end_at' => $end->timestamp,
    ]);

    return redirect()->route('admin.subscription.index')
                     ->with('success', 'Subscription created successfully!');
}


    // Show details of a specific subscription
    public function show($id)
    {
		 if (Session::get('role') != 'admin') {
            return redirect('admin');
        }
        $subscription = Subscription::with('user')->findOrFail($id);
        return view('Admin.subscriptions.show', compact('subscription'));
    }

    // Update subscription details
    public function update(Request $request, $id)
    {
		 if (Session::get('role') != 'admin') {
            return redirect('admin');
        }
        $subscription = Subscription::findOrFail($id);

        $request->validate([
            'amount' => 'required|numeric',
            'duration' => 'required|numeric',
            'title' => 'nullable|string',
			'description' => 'nullable|string',
        ]);

        $start = Carbon::now();
        $end = $start->copy()->addMonths($request->duration);

        $subscription->update([
    'amount' => $request->amount,
    'title' => $request->title,
	'description' => $request->description,
    'duration' => $request->duration,
    'start_at' => $start->timestamp,
    'end_at' => $end->timestamp,
]);

       return redirect()->route('admin.subscription.index')
                 ->with('success', 'Subscription created successfully!');
    }
	
	public function destroy($id)
{
    if (Session::get('role') != 'admin') {
        return redirect('admin');
    }

    $subscription = Subscription::findOrFail($id);
    $subscription->delete();

    return redirect()->route('admin.subscription.index')
                     ->with('success', 'Subscription deleted successfully!');
}
}
