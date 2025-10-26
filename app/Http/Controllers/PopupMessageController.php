<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\PopupMessage;
use Carbon\Carbon;
use Illuminate\Support\Facades\Session;

class PopupMessageController extends Controller
{
    public function index()
    {
		 if (Session::get('role') != 'admin') {
            return redirect('admin');
        }
        // Temporary: Use empty collection if table doesn't exist
        try {
            $messages = PopupMessage::orderBy('created_at', 'desc')->get();
        } catch (\Exception $e) {
            $messages = collect(); // Empty collection for testing
        }
        return view('Admin.popup_messages.index', compact('messages'));
    }

    public function create()
    {
		 if (Session::get('role') != 'admin') {
            return redirect('admin');
        }
        return view('Admin.popup_messages.create');
    }

    public function store(Request $request)
    {
		 if (Session::get('role') != 'admin') {
            return redirect('admin');
        }
        $request->validate([
            'title' => 'required|string|max:255',
            'message' => 'required|string',
            'user_type' => 'required|in:driver,transporter,both',
            'status' => 'boolean',
            'start_date' => 'nullable|date',
            'end_date' => 'nullable|date|after_or_equal:start_date',
            'priority' => 'required|in:high,normal,low'
        ]);

        PopupMessage::create([
            'title' => $request->title,
            'message' => $request->message,
            'user_type' => $request->user_type,
            'status' => $request->status ?? 1,
            'start_date' => $request->start_date ? Carbon::parse($request->start_date) : null,
            'end_date' => $request->end_date ? Carbon::parse($request->end_date) : null,
            'priority' => $request->priority
        ]);

        return redirect()->route('admin.popup-messages.index')
            ->with('success', 'Popup message created successfully!');
    }

    public function edit($id)
    {
		 if (Session::get('role') != 'admin') {
            return redirect('admin');
        }
        $message = PopupMessage::findOrFail($id);
        return view('Admin.popup_messages.edit', compact('message'));
    }

    public function update(Request $request, $id)
    {
		 if (Session::get('role') != 'admin') {
            return redirect('admin');
        }
        $message = PopupMessage::findOrFail($id);

        $request->validate([
            'title' => 'required|string|max:255',
            'message' => 'required|string',
            'user_type' => 'required|in:driver,transporter,both',
            'status' => 'boolean',
            'start_date' => 'nullable|date',
            'end_date' => 'nullable|date|after_or_equal:start_date',
            'priority' => 'required|in:high,normal,low'
        ]);

        $message->update([
            'title' => $request->title,
            'message' => $request->message,
            'user_type' => $request->user_type,
            'status' => $request->status ?? 0,
            'start_date' => $request->start_date ? Carbon::parse($request->start_date) : null,
            'end_date' => $request->end_date ? Carbon::parse($request->end_date) : null,
            'priority' => $request->priority
        ]);

        return redirect()->route('admin.popup-messages.index')
            ->with('success', 'Popup message updated successfully!');
    }

    public function destroy($id)
    {
		 if (Session::get('role') != 'admin') {
            return redirect('admin');
        }
        $message = PopupMessage::findOrFail($id);
        $message->delete();

        return redirect()->route('admin.popup-messages.index')
            ->with('success', 'Popup message deleted successfully!');
    }

    public function toggleStatus($id)
    {
        $message = PopupMessage::findOrFail($id);
        $message->update(['status' => !$message->status]);

        return redirect()->route('admin.popup-messages.index')
            ->with('success', 'Message status updated successfully!');
    }

    // API method to get active popup messages for frontend
    public function getActiveMessages(Request $request)
    {
        $audience = $request->get('audience', 'both'); // driver, transporter, or both

        $messages = PopupMessage::active()
            ->forAudience($audience)
            ->currentlyActive()
            ->ordered()
            ->get();

        return response()->json([
            'success' => true,
            'messages' => $messages
        ]);
    }
    public function upload(Request $request)
    {
        if ($request->hasFile('upload')) {
            $file = $request->file('upload');
            $filename = time() . '_' . $file->getClientOriginalName();
            $file->move(public_path('uploads/ckeditor'), $filename);
            $url = asset('public/uploads/ckeditor/' . $filename);

            return response()->json([
                'uploaded' => 1,
                'fileName' => $filename,
                'url' => $url
            ]);
        }

        return response()->json([
            'uploaded' => 0,
            'error' => ['message' => 'Cannot upload file']
        ]);
    } 
}
