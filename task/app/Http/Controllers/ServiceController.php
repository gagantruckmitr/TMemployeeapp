<?php

namespace App\Http\Controllers;

use App\Models\Service;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class ServiceController extends Controller
{
    public function index()
    {
        $services = Service::all();
        return view('services.index', compact('services'));
    }

    public function create()
    {
        return view('services.add');
    }

    public function store(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'description' => 'nullable|string'
        ]);

        do {
            $serviceId = strtoupper(Str::random(8));
        } while (Service::where('service_id', $serviceId)->exists());

        Service::create([
            'service_id' => $serviceId,
            'name' => $request->name,
            'description' => $request->description,
        ]);

        return redirect()->route('services.index')->with('success', 'Service added successfully');
    }

    public function edit($id)
    {
        $service = Service::findOrFail($id);
        return view('services.edit', compact('service'));
    }

    public function update(Request $request, $id)
    {
        $service = Service::findOrFail($id);

        $request->validate([
            'name' => 'required|string|max:255',
            'description' => 'nullable|string'
        ]);

        $service->update([
            'name' => $request->name,
            'description' => $request->description,
        ]);

        return redirect()->route('services.index')->with('success', 'Service updated successfully');
    }

    public function destroy($id)
    {
        $service = Service::findOrFail($id);
        $service->delete();

        return redirect()->route('services.index')->with('success', 'Service deleted successfully');
    }
}