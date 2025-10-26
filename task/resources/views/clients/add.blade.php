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
    <h2>Add Client</h2>

    <form action="{{ route('clients.store') }}" method="POST">
        @csrf

        <div class="mb-3">
            <label>Name</label>
            <input name="name" class="form-control" required>
        </div>
        
           <div class="row">
             <div class="col-md-6">
              {{-- ✅ New: Client Onboarding Date --}}
        <div class="mb-3">
            <label>Client Onboarding Date</label>
            <input type="date" name="onboarding_date" class="form-control" required>
        </div>
            
        </div>
        
        <div class="col-md-6">
             {{-- ✅ New: Project Owner --}}
        <div class="mb-3">
            <label>Project Owner</label>
            <input type="text" name="project_owner" class="form-control" required>
        </div>
        </div>
        </div>
        
           <div class="mb-3">
            <label>Description</label>
            <textarea name="description" class="form-control"></textarea>
        </div>

      <div class="mb-3">
    <label class="form-label">Select Services:</label>
    <div class="row" id="service-list">
        @foreach($services as $service)
            <div class="col-md-4 mb-4">
                <div class="border rounded p-3 h-100 shadow-sm service-card">
                    <div class="form-check">
                        <input type="checkbox" class="form-check-input service-checkbox" id="service_{{ $service->id }}"
                               name="services[{{ $service->id }}][name]" value="{{ $service->name }}">
                        <label class="form-check-label" for="service_{{ $service->id }}">
                            {{ $service->name }}
                        </label>
                    </div>

                    <div class="mt-2 cost-input d-none">
                        <label for="cost_{{ $service->id }}" class="form-label small text-muted">Service Cost:</label>
                        <input type="number" class="form-control cost-field"
                               name="services[{{ $service->id }}][cost]" placeholder="₹ Enter cost">
                    </div>
                </div>
            </div>
        @endforeach
    </div>
</div>

    

     
        
     
        
        <h5>Total Project Cost</h5>
    <table class="table table-bordered mt-3" id="cost-summary">
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
        
       

      

       

        <button class="btn btn-success dxBtn btn-sm">Save</button>
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
    document.addEventListener('DOMContentLoaded', function () {
        const checkboxes = document.querySelectorAll('.service-checkbox');
        const costSummaryTable = document.querySelector('#cost-summary tbody');
        const totalCostDisplay = document.querySelector('#total-cost');

        function updateSummary() {
            costSummaryTable.innerHTML = '';
            let total = 0;

            checkboxes.forEach((checkbox) => {
                const card = checkbox.closest('.border'); // Use correct parent container
                const costInput = card.querySelector('.cost-field');
                const serviceName = checkbox.value;

                if (checkbox.checked && costInput.value) {
                    const cost = parseFloat(costInput.value) || 0;
                    total += cost;

                    const row = document.createElement('tr');
                    row.innerHTML = `<td>${serviceName}</td><td>₹${cost.toLocaleString()}</td>`;
                    costSummaryTable.appendChild(row);
                }
            });

            totalCostDisplay.textContent = `₹${total.toLocaleString()}`;
        }

        checkboxes.forEach((checkbox) => {
            const card = checkbox.closest('.border');
            const costWrapper = card.querySelector('.cost-input');
            const costField = costWrapper.querySelector('.cost-field');

            checkbox.addEventListener('change', function () {
                costWrapper.classList.toggle('d-none', !this.checked);
                updateSummary();
            });

            costField.addEventListener('input', updateSummary);
        });
    });
</script>
<script>
  $(document).ready(function () {
    $('.service-checkbox').on('change', function () {
        const isChecked = $(this).is(':checked');
        const card = $(this).closest('.service-card');
        const costInput = card.find('.cost-input');

        if (isChecked) {
            card.css('cssText', 'border: 2px solid #03b4e5 !important');
            costInput.removeClass('d-none');
        } else {
            card.css('cssText', 'border: 2px solid #dee2e6 !important'); // original Bootstrap border color
            costInput.addClass('d-none');
        }
    });
});
</script>

@endpush
