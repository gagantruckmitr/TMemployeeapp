<?php

namespace App\Http\Controllers;

use App\Models\WhatsappGroup;
use App\Models\WhatsappGroupMember;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Session;


 

class WhatsappGroupController extends Controller
{
    public function index()
    {
        if (empty(Session::get('role') == 'admin')) {
			return redirect('admin');
		}
		$groups = WhatsappGroup::withCount('members')->latest()->get();
        return view('Admin.whatsapp_groups.index', compact('groups'));
    }

    public function create()
    {
        return view('Admin.whatsapp_groups.create');
    }

    public function store(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'description' => 'nullable|string',
        ]);

        WhatsappGroup::create([
            'group_type' => $request->group_type,
			'name' => $request->name,
            'whatsapp_group_link' => $request->whatsapp_group_link,
			'max_members' => $request->max_members,
            'created_by' => auth()->id(),
        ]);

        return redirect()->route('admin.whatsapp_groups.index')->with('success', 'Group created successfully.');
    }

    public function edit($id)
    {
        $group = WhatsappGroup::findOrFail($id);
        return view('Admin.whatsapp_groups.edit', compact('group'));
    }

    public function update(Request $request, $id)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'whatsapp_group_link' => 'required|string|max:255',
        ]);

        $group = WhatsappGroup::findOrFail($id);
        $group->update($request->only(['name', 'whatsapp_group_link','max_members', 'status']));

        return redirect()->route('admin.whatsapp_groups.index')->with('success', 'Group updated successfully.');
    }

    public function destroy($id)
    {
        $group = WhatsappGroup::findOrFail($id);
        $group->delete();

        return redirect()->back()->with('success', 'Group deleted successfully.');
    }

    public function members($id)
    {
        $group = WhatsappGroup::with('members.user')->findOrFail($id);
        $users = User::all();
        return view('Admin.whatsapp_groups.members', compact('group', 'users'));
    }

    public function addMember(Request $request)
    {
        $request->validate([
            'group_id' => 'required|exists:whatsapp_groups,id',
            'user_id' => 'required|exists:users,id',
            'user_type' => 'required|in:driver,transporter,admin',
        ]);

        WhatsappGroupMember::create($request->only(['group_id', 'user_id', 'user_type']));

        return redirect()->back()->with('success', 'Member added successfully.');
    }

    public function removeMember($id)
    {
        $member = WhatsappGroupMember::findOrFail($id);
        $member->delete();

        return redirect()->back()->with('success', 'Member removed successfully.');
    }
}
