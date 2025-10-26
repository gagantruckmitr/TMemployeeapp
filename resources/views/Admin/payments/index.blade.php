@include('Admin.layouts.header')

<div class="page-wrapper">
    <div class="card shadow content container-fluid">
        <div class="card-header bg-primary text-white">
            <h4 class="mb-0">Payments List</h4>
        </div>
        <div class="card-body">
            <table class="table table-bordered table-hover table-striped">
                <thead class="thead-dark">
                    <tr>
                        <th>Payment ID</th>
                        <th>User</th>
                        <th>Amount (INR)</th>
                        <th>Status</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody>
                    @foreach ($payments as $payment)
                        <tr>
                            <td>{{ $payment->id }}</td>
                            <td>{{ optional($payment->user)->name ?? 'No User' }}</td>
                            <td>{{ $payment->amount }}</td>
                            <td>
                                <span class="badge {{ $payment->payment_status == 'captured' ? 'badge-success' : 'badge-danger' }}">
                                    {{ ucfirst($payment->payment_status) }}
                                </span>
                            </td>
                          <td>
                                <a href="{{ route('admin.payment.show', $payment->id) }}" class="btn btn-info btn-sm">View</a>
                                <form action="{{ route('admin.payment.destroy', $payment->id) }}" method="POST" class="d-inline">
                                    @csrf
                                    @method('DELETE')
                                    <button type="submit" class="btn btn-danger btn-sm">Delete</button>
                                </form>
                            </td>
                        </tr>
                    @endforeach
                </tbody>
            </table>

            <!-- Pagination links -->
            <div class="pagination justify-content-center">
                {{ $payments->links('pagination::bootstrap-4') }}
            </div>
        </div>
    </div>
</div>

@include('Admin.layouts.footer')
