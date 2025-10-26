@extends('layouts.sidebar')

@section('content')
<div class="container">
       <button
    class="btn btn-outline-dark rounded-circle mb-3 d-flex align-items-center justify-content-center"
    style="width: 40px; height: 40px;"
    onclick="history.back()"
>
    <i class="bi bi-arrow-left"></i>
</button>
    <h2>Edit Client</h2>

    <form action="{{ route('clients.update', $client->client_id) }}" method="POST">
        @csrf
        @method('PUT')

        <div class="mb-3">
            <label>Name</label>
            <input name="name" class="form-control" value="{{ $client->name }}" required>
        </div>
        
        <div class="row">
    <div class="col-md-6">
          {{-- ✅ New: Client Onboarding Date --}}
        <div class="mb-3">
            <label>Client Onboarding Date</label>
            <input type="date" name="onboarding_date" class="form-control"
                   value="{{ $client->onboarding_date }}" required>
        </div>
    </div>
    <div class="col-md-6">
          {{-- ✅ New: Project Owner --}}
        <div class="mb-3">
            <label>Project Owner</label>
            <input type="text" name="project_owner" class="form-control"
                   value="{{ $client->project_owner }}" required>
        </div>
    </div>
</div>
        
        <div class="mb-3">
            <label>Description</label>
            <textarea name="description" class="form-control">{{ $client->description }}</textarea>
        </div>

        <div class="mb-3">
    <label class="form-label">Select Services:</label>
    <div id="service-list" class="row row-cols-1 row-cols-md-2 row-cols-lg-3 g-3">
        @php
           
    $selectedServices = old('services', $client->service ?? []);
    $totalCost = 0;
 
        @endphp

        @foreach ($services as $service)
            @php
                $isChecked = isset($selectedServices[$service->id]);
                $cost = $isChecked ? ($selectedServices[$service->id]['cost'] ?? 0) : '';
                $totalCost += $isChecked ? (float) $cost : 0;
            @endphp

            <div class="col">
                <div class="border p-3 rounded shadow-sm service-card"
                     style="{{ $isChecked ? 'border: 2px solid #03b4e5 !important;' : '' }}">
                    <div class="form-check">
                        <input type="checkbox"
                               class="form-check-input service-checkbox"
                               id="service_{{ $service->id }}"
                               name="services[{{ $service->id }}][name]"
                               value="{{ $service->name }}"
                               {{ $isChecked ? 'checked' : '' }}>
                        <label class="form-check-label" for="service_{{ $service->id }}">{{ $service->name }}</label>
                    </div>

                    <div class="mt-2 cost-input {{ $isChecked ? '' : 'd-none' }}">
                        <input type="number"
                               class="form-control cost-field"
                               name="services[{{ $service->id }}][cost]"
                               placeholder="₹ Enter cost for {{ $service->name }}"
                               value="{{ old("services.{$service->id}.cost", $cost) }}">
                    </div>
                </div>
            </div>
        @endforeach
    </div>
</div>

<div class="mt-3">
    <strong>Total Project Cost:</strong> ₹ <span id="total-cost">{{ $totalCost }}</span>
</div>


        

      

      
        
        <div class="mt-4">
    <h5>Cost Summary</h5>
    <table class="table table-bordered" id="cost-summary">
        <thead>
            <tr>
                <th>Service</th>
                <th>Cost</th>
            </tr>
        </thead>
        <tbody></tbody>
        <tfoot>
            <tr>
                <th>Total</th>
                <th id="total-cost">₹0</th>
            </tr>
        </tfoot>
    </table>
</div>

        <button class="btn btn-primary btn-sm dxBtn">Update</button>
    </form>
</div>
@endsection

@push('scripts')
<script>
    $(document).ready(function() {
        $('#service').select2({
            tags: true,
            placeholder: 'Select services',
            width: '100%'
        });
    });
</script>
<script>
    $(document).ready(function () {
        function updateTotalCost() {
            let total = 0;
            $('.cost-field:visible').each(function () {
                let val = parseFloat($(this).val());
                if (!isNaN(val)) total += val;
            });
            $('#total-cost').text(total.toFixed(2));
        }

        $('.service-checkbox').on('change', function () {
            const isChecked = $(this).is(':checked');
            const card = $(this).closest('.service-card');
            const costInput = card.find('.cost-input');

            if (isChecked) {
                card.css('border', '2px solid #03b4e5').css('border-radius', '0.375rem'); // keep rounded class look
                costInput.removeClass('d-none');
            } else {
                card.css('border', '').css('border-radius', '0.375rem');
                costInput.addClass('d-none');
                costInput.find('.cost-field').val('');
            }

            updateTotalCost();
        });

        $('.cost-field').on('input', function () {
            updateTotalCost();
        });

        // Initial load
        updateTotalCost();
    });
</script>

@endpush
