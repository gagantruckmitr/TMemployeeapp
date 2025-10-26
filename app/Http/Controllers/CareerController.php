<?php
namespace App\Http\Controllers;

use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Storage;
use Illuminate\Http\Request;
use App\Models\Career;
use App\Models\Inquery;
use Illuminate\Support\Facades\Session;

class CareerController extends Controller
{
    	
	// Admin: List all careers
    public function index()
    {
		 if (Session::get('role') != 'admin') {
            return redirect('admin');
        }
        $careers = Career::orderBy('date_posted', 'desc')->get();
        return view('Admin.career.index', compact('careers'));
    }

    // Admin: Show create form
    public function create()
    {
		 if (Session::get('role') != 'admin') {
            return redirect('admin');
        }
        return view('Admin.career.create');
    }

    // Admin: Store new career
    public function store(Request $request)
    {
		 if (Session::get('role') != 'admin') {
            return redirect('admin');
        }
        $request->validate([
            'position_title' => 'required|string|max:255',
			'position_location' => 'required|string|max:255',
            'description' => 'required|string',
            'key_responsibilities' => 'required|string',
            'qualification' => 'required|string',
            'hiring_organization' => 'required|string|max:255',
            'job_location' => 'required|string|max:255',
            'date_posted' => 'required|date',
            'contact_email' => 'nullable|email',
            'contact_phone' => 'nullable|string|max:20',
            'contact_address' => 'nullable|string|max:255',
        ]);

        Career::create($request->all());

        return redirect()->route('career.index')->with('success', 'Career added successfully.');
    }

    // Admin: Show edit form
    public function edit($id)
    {
		 if (Session::get('role') != 'admin') {
            return redirect('admin');
        }
        $career = Career::findOrFail($id);
        return view('Admin.career.edit', compact('career'));
    }

    // Admin: Update career
    public function update(Request $request, $id)
    {
		 if (Session::get('role') != 'admin') {
            return redirect('admin');
        }
        $request->validate([
            'position_title' => 'required|string|max:255',
			'position_location' => 'required|string|max:255',
            'description' => 'required|string',
            'key_responsibilities' => 'required|string',
            'qualification' => 'required|string',
            'hiring_organization' => 'required|string|max:255',
            'job_location' => 'required|string|max:255',
            'date_posted' => 'required|date',
            'contact_email' => 'nullable|email',
            'contact_phone' => 'nullable|string|max:20',
            'contact_address' => 'nullable|string|max:255',
        ]);

        $career = Career::findOrFail($id);
        $career->update($request->all());

        return redirect()->route('career.index')->with('success', 'Career updated successfully.');
    }

    // Admin: Delete career
    public function destroy($id)
    {
		 if (Session::get('role') != 'admin') {
            return redirect('admin');
        }
        $career = Career::findOrFail($id);
        $career->delete();
        return redirect()->route('career.index')->with('success', 'Career deleted successfully.');
    }

    // Frontend: List all careers
    public function careerList()
    {
		 
        $careers = Career::orderBy('date_posted', 'desc')->get();
        return view('Fronted.career', compact('careers'));
    }

    // Frontend: Show career detail
    public function careerDetails($id)
{
		
    $career = Career::findOrFail($id);
    return view('Fronted.career-details', compact('career'));
}

public function apply(Request $request)
{
	
    $request->validate([
    'name'   => 'required|string|max:100',
    'email'  => 'required|email',
    'phone'  => [
        'required',
        'regex:/^[6-9][0-9]{9}$/',
    ],
    'resume' => 'required|mimes:pdf,doc,docx|max:2048',
], [
    'phone.regex' => 'Phone number must be 10 digits and start with 6, 7, 8, or 9.',
]);

    // Move file to /public/resumes
    if ($request->hasFile('resume')) {
        $resume = $request->file('resume');
        $resumeName = time() . '.' . $resume->getClientOriginalExtension();
        $resume->move(public_path('resumes'), $resumeName);
        $resumePath = 'resumes/' . $resumeName;
    }

    // Save to DB
    inquery::create([
        'name' => $request->name,
        'email' => $request->email,
        'phone' => $request->phone,
        'resume' => $resumePath,
    ]);

    // Optional Email Notification
    Mail::raw("New Career Application from {$request->name} ({$request->email})", function ($message) use ($request, $resumePath) {
        $message->to('singhrahulbly123@gmail.com')
                ->subject('New Career Application')
                ->attach(public_path($resumePath));
    });

    return back()->with('success', 'Application submitted successfully!');
}
public function showInquiries()
{
	 if (Session::get('role') != 'admin') {
            return redirect('admin');
        }
    $inquiries = \App\Models\Inquery::orderBy('created_at', 'desc')->get();

    return view('Admin.inquery.index', compact('inquiries'));
}
}

