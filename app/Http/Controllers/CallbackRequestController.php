<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\CallbackRequest;
use App\Mail\CallbackRequestMail;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Session;
use Maatwebsite\Excel\Facades\Excel;
use App\Exports\CallbackRequestExport;
use Carbon\Carbon;
use App\Models\Job;
use Illuminate\Support\Facades\Auth;
use App\Models\Admin;


class CallbackRequestController extends Controller
{
 public function index()
{
    $role = Session::get('role');
    $userId = Session::get('id');

    // Check role validity
    if (!in_array($role, ['admin', 'telecaller', 'manager'])) {
        return redirect('admin')->with('msg', 'Access denied.');
    }

    // Get callback requests based on role
    if (in_array($role, ['admin', 'manager'])) {
        $callbackRequests = CallbackRequest::with('telecaller')
            ->orderBy('created_at', 'desc')
            ->get();

        // Admin-specific view (optional)
        return view('Admin.callback-requests.index', compact('callbackRequests'));

    } elseif ($role === 'telecaller') {
        $callbackRequests = CallbackRequest::with('telecaller')
            ->where('assigned_to', $userId)
            ->orderBy('created_at', 'desc')
            ->get();

        // Telecaller-specific view (optional)
        return view('Telecaller.callback-requests.index', compact('callbackRequests'));
    }

    // Fallback
    return redirect('/')->with('msg', 'Invalid access.');
}

	
    public function create()
    {
	
        return view('Admin.callback-requests.create');
    }

    public function store(Request $request)
{
    // 1️⃣ Validate incoming request
    $request->validate([
        'user_name' => 'required|string|max:255',
        'mobile_number' => 'required|string|max:15',
        'request_date_time' => 'required|date',
        'contact_reason' => 'required|string|max:255',
        'app_type' => 'required|in:driver,transporter',
        'notes' => 'nullable|string'
    ]);

    $telecallers = Admin::where('role', 'telecaller')->orderBy('id')->get();

// Check if there are no telecallers available
if ($telecallers->isEmpty()) {
    return redirect()->back()->with('error', 'No telecallers available.');
}

// Debugging: Dump the telecallers' IDs to make sure they're being fetched properly
//dd($telecallers->pluck('id'));

// Get the last assigned telecaller ID from the most recent lead
$lastLead = CallbackRequest::whereIn('assigned_to', $telecallers->pluck('id'))->latest()->first();

// Debugging: Dump the last lead to see the result
//dd($lastLead);

// Decide who gets the next lead
if (!$lastLead) {
    // No previous leads: assign to the first telecaller
    $nextTelecaller = $telecallers->first();
} else {
    // Find the index of the last telecaller
    $lastIndex = $telecallers->search(function ($telecaller) use ($lastLead) {
        return $telecaller->id === $lastLead->assigned_to;
    });

    // Get the next telecaller in round-robin
    $nextIndex = ($lastIndex + 1) % $telecallers->count();
    $nextTelecaller = $telecallers[$nextIndex];
}

// Debugging: Check if the next telecaller is correctly set
//dd($nextTelecaller->id);

// Check if the next telecaller is valid before creating the callback request
if (is_null($nextTelecaller)) {
    return redirect()->back()->with('error', 'No telecaller available to assign.');
}

// Create a new callback request and assign it to the next telecaller
$callbackRequest = CallbackRequest::create([
    'user_name' => $request->user_name,
    'mobile_number' => $request->mobile_number,
    'request_date_time' => $request->request_date_time,
    'contact_reason' => $request->contact_reason,
    'app_type' => $request->app_type,
    'notes' => $request->notes,
    'status' => 'pending',
    'assigned_to' => (int) $nextTelecaller->id,  // Explicitly cast to integer
]);


    // 7️⃣ Send email notification
    try {
        Mail::to('contact@truckmitr.com')->send(new CallbackRequestMail($callbackRequest));
    } catch (\Exception $e) {
        \Log::error('Failed to send callback request email: ' . $e->getMessage());
    }

    return redirect()
        ->route('admin.callback-requests.index')
        ->with('success', 'Callback request created successfully and assigned to ' . $nextTelecaller->user_name);
}


  public function edit($id)
{
    $role = Session::get('role');
    $userId = Session::get('id');

    // Allow only admin or telecaller
    if (!in_array($role, ['admin', 'telecaller','manager'])) {
        return redirect('admin')->with('msg', 'Access denied.');
    }

    // Get the callback request
    $callbackRequest = CallbackRequest::findOrFail($id);

    // If telecaller, ensure they can only access their assigned requests
    if ($role === 'telecaller' && $callbackRequest->assigned_to != $userId) {
        return redirect()->route('telecaller.callback-requests.index')
                         ->with('msg', 'You are not authorized to edit this request.');
    }

    // Load role-specific view (optional)
    if (in_array($role, ['admin', 'manager'])) {
        return view('Admin.callback-requests.edit', compact('callbackRequest'));
    } else {
        return view('Telecaller.callback-requests.edit', compact('callbackRequest'));
    }
}


       public function update(Request $request, $id)
{
    $role = Session::get('role');
    $userId = Session::get('id');

    // Restrict access to only admin or telecaller
    if (!in_array($role, ['admin', 'telecaller','manager'])) {
        return redirect('admin')->with('msg', 'Access denied.');
    }

    // Find the callback request
    $callbackRequest = CallbackRequest::findOrFail($id);

    // If telecaller, ensure they are assigned to this request
    if ($role === 'telecaller' && $callbackRequest->assigned_to != $userId) {
        return redirect()->route('telecaller.callback-requests.index')
                         ->with('msg', 'Unauthorized to update this request.');
    }

    // Validate input
    $request->validate([
        'user_name' => 'required|string|max:255',
        'mobile_number' => 'required|string|max:15',
        'request_date_time' => 'required|date',
        'contact_reason' => 'required|string|max:255',
        'app_type' => 'required|in:driver,transporter',
        'status' => 'required|in:pending,contacted,resolved',
        'notes' => 'nullable|string'
    ]);

    // Update the record
    $callbackRequest->update([
        'user_name' => $request->user_name,
        'mobile_number' => $request->mobile_number,
        'request_date_time' => $request->request_date_time,
        'contact_reason' => $request->contact_reason,
        'app_type' => $request->app_type,
        'status' => $request->status,
        'notes' => $request->notes
    ]);

    // Redirect to appropriate route
    if (in_array($role, ['admin', 'manager'])) {
        return redirect()->route('admin.callback-requests.index')
                         ->with('success', 'Callback request updated successfully!');
    } else {
        return redirect()->route('telecaller.callback-requests.index')
                         ->with('success', 'Callback request updated successfully!');
    }
}


    public function destroy($id)
    {
		 if (Session::get('role') != 'admin') {
            return redirect('admin');
        }
        $callbackRequest = CallbackRequest::findOrFail($id);
        $callbackRequest->delete();
        
        return redirect()->route('admin.callback-requests.index')->with('success', 'Callback request deleted successfully!');
    }

   public function updateStatus(Request $request, $id)
{
    $role = Session::get('role');
    $userId = Session::get('id');

    // Restrict access to only admin or telecaller
    if (!in_array($role, ['admin', 'telecaller','manager'])) {
        return redirect('admin')->with('msg', 'Access denied.');
    }

    // Find the callback request
    $callbackRequest = CallbackRequest::findOrFail($id);

    // If telecaller, only allow access to their own assigned requests
    if ($role === 'telecaller' && $callbackRequest->assigned_to != $userId) {
        return redirect()->route('telecaller.callback-requests.index')
                         ->with('msg', 'Unauthorized to update this request.');
    }

    // Validate the request
    $request->validate([
       'status' => 'required|in:Pending,Contacted,Resolved,Ringing / Call Busy,Disconnected,Callback,Swtiched Off / Out of Service or Network,Interested,Not Interested,Future Prospects,',
        'notes' => 'nullable|string'
    ]);

    // Update status and notes
    $callbackRequest->update([
        'status' => $request->status,
        'notes' => $request->notes
    ]);

    // Redirect role-wise
    if (in_array($role, ['admin', 'manager'])) {
        return redirect()->route('admin.callback-requests.index')
                         ->with('success', 'Callback request status updated successfully!');
    } else {
        return redirect()->route('telecaller.callback-requests.index')
                         ->with('success', 'Callback request status updated successfully!');
    }
}

   public function show($id)
{
    $role = Session::get('role');
    $userId = Session::get('id');

    if (!in_array($role, ['admin', 'telecaller','manager'])) {
        return redirect('admin')->with('msg', 'Access denied.');
    }

    $callbackRequest = CallbackRequest::findOrFail($id);

    // Telecaller can only view their own assigned requests
    if ($role === 'telecaller' && $callbackRequest->assigned_to != $userId) {
        return redirect()->route('telecaller.callback-requests.index')
                         ->with('msg', 'Unauthorized access.');
    }

    // Return role-wise views
    if (in_array($role, ['admin', 'manager'])) {
        return view('Admin.callback-requests.show', compact('callbackRequest'));
    } else {
        return view('Telecaller.callback-requests.show', compact('callbackRequest'));
    }
}
	

// API endpoint for mobile apps to submit callback requests
    public function apiStore(Request $request)
    {
        $request->validate([
            'contact_reason' => 'required|string|max:255'
        ]);

        // Get the authenticated user from the token
        $user = auth('api')->user();
        
        if (!$user) {
            return response()->json([
                'status' => false,
                'message' => 'User not authenticated'
            ], 401);
        }

        // Get app_type from user's role
        $appType = $user->role; // 'driver' or 'transporter'
		
		
		
$telecallers = Admin::where('role', 'telecaller')->orderBy('id')->get();

// 1. Check if there are telecallers available
if ($telecallers->isEmpty()) {
    return redirect()->back()->with('error', 'No telecallers available.');
}

// 2. Check if this mobile number already exists in callback requests
$existingLead = CallbackRequest::where('mobile_number', $user->mobile)
    ->whereNotNull('assigned_to')
    ->latest()
    ->first();

if ($existingLead && in_array($existingLead->assigned_to, $telecallers->pluck('id')->toArray())) {
    // ✅ Same telecaller if mobile number is already assigned
    $nextTelecaller = $telecallers->firstWhere('id', $existingLead->assigned_to);
} else {
    // 3. No previous assignment — do round-robin

    // Get the last lead assigned to any of the current telecallers
    $lastLead = CallbackRequest::whereIn('assigned_to', $telecallers->pluck('id'))
        ->latest()
        ->first();

    if (!$lastLead) {
        // ✅ No previous lead exists, assign to first telecaller
        $nextTelecaller = $telecallers->first();
    } else {
        // ✅ Round-robin: find index of last telecaller
        $lastIndex = $telecallers->search(function ($telecaller) use ($lastLead) {
            return $telecaller->id === $lastLead->assigned_to;
        });

        // Get the next telecaller in the list
        $nextIndex = ($lastIndex + 1) % $telecallers->count();
        $nextTelecaller = $telecallers[$nextIndex];
    }
}

// 4. Safety check
if (is_null($nextTelecaller)) {
    return redirect()->back()->with('error', 'No telecaller could be selected.');
}

// 5. Save the new callback request
$callbackRequest = CallbackRequest::create([
    'unique_id' => $user->unique_id ?? uniqid('CB'),
    'user_name' => $user->name,
    'mobile_number' => $user->mobile,
    'request_date_time' => now(),
    'contact_reason' => $request->contact_reason,
    'app_type' => $appType,
    'status' => 'pending',
    'assigned_to' => (int) $nextTelecaller->id,
]);


        // // Send email notification
        try {
            Mail::to('contact@truckmitr.com')->send(new CallbackRequestMail($callbackRequest));
        } catch (\Exception $e) {
            // Log the error but don't fail the request
            \Log::error('Failed to send callback request email: ' . $e->getMessage());
        }

        return response()->json([
            'status' => true,
            'message' => 'Callback request submitted successfully',
            'data' => $callbackRequest
        ], 201);
    }
	
	// Export callback request 
	
	public function showForm()
    {
        return view('Admin.callback-requests.index'); // Blade view with date inputs
    }

    public function export(Request $request)
    {
        $request->validate([
            'from_date' => 'required|date',
            'to_date' => 'required|date|after_or_equal:from_date',
        ]);

        return Excel::download(new CallbackRequestExport($request->from_date,$request->to_date), 'callback_request_export.xlsx');
    }
	
	
}