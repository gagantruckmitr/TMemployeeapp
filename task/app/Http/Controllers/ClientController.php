<?php

namespace App\Http\Controllers;

use App\Models\Client;
use App\Models\Service;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class ClientController extends Controller
{
    public function index()
    {
        $clients = Client::all();
        return view('clients.index', compact('clients'));
    }

    public function create()
    {
        $services = Service::all(); // Fetch all services from DB
        return view('clients.add', compact('services'));
    }

    public function store(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'services' => 'required|array',
            'description' => 'nullable|string',
            'onboarding_date' => 'required|date',
            'project_owner' => 'required|string|max:255',
        ]);

        $clientId = strtoupper(Str::random(4)); // Auto-generated client ID

        Client::create([
            'client_id' => $clientId,
            'name' => $request->name,
            'service' => json_encode($request->services), // Save as JSON
            'description' => $request->description,
            'onboarding_date' => $request->onboarding_date,
            'project_owner' => $request->project_owner,
        ]);

        return redirect()->route('clients.index')->with('success', 'Client added successfully');
    }

    public function edit($client_id)
{
    $client = Client::where('client_id', $client_id)->firstOrFail();
    $services = Service::all();
    return view('clients.edit', compact('client', 'services'));
}

public function update(Request $request, $client_id)
{
    $client = Client::where('client_id', $client_id)->firstOrFail();

    $request->validate([
        'name' => 'required|string|max:255',
        'services' => 'required|array',
        'description' => 'nullable|string',
        'onboarding_date' => 'required|date',
        'project_owner' => 'required|string|max:255',
    ]);

    $client->update([
        'name' => $request->name,
        'service' => json_encode($request->services),
        'description' => $request->description,
        'onboarding_date' => $request->onboarding_date,
        'project_owner' => $request->project_owner,
    ]);

    return redirect()->route('clients.index')->with('success', 'Client updated successfully!');
}

  public function destroy($client_id)
{
    $client = Client::where('client_id', $client_id)->firstOrFail();
    $client->delete();

    return redirect()->route('clients.index')->with('success', 'Client deleted successfully!');
}

    public function getClientsData()
    {
        return datatables(Client::select(['id', 'client_id', 'name']))->make(true);
    }
}
