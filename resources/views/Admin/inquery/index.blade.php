@include('Admin.layouts.header')

<h2 style="text-align:center; margin: 24px 0; font-family: 'Roboto', Arial, sans-serif; font-weight: 500; color: #202124;">
    Career Inquiries
</h2>

@if($inquiries->isEmpty())
    <p style="text-align:center; font-size: 1rem; color: #5f6368; font-family: 'Roboto', Arial, sans-serif;">No inquiries found.</p>
@else
<div class="page-wrapper" style="background:white">
  <div class="content container-fluid">

    <table class="google-style-table" role="grid" aria-label="Career Inquiries">
        <thead>
            <tr>
                <th scope="col">#</th>
                <th scope="col">Name</th>
                <th scope="col">Email</th>
                <th scope="col">Phone</th>
                <th scope="col">Resume</th>
                <th scope="col">Date</th>
            </tr>
        </thead>
        <tbody>
            @foreach($inquiries as $inquiry)
                <tr>
                    <td>{{ $loop->iteration }}</td>
                    <td>{{ $inquiry->name }}</td>
                    <td>{{ $inquiry->email }}</td>
                    <td>{{ $inquiry->phone }}</td>
                    <td><a href="{{ url('public/' . $inquiry->resume) }}" target="_blank" class="resume-link">Download</a></td>
                    <td>{{ date('d M Y, h:i A', strtotime($inquiry->created_at)) }}</td>
                </tr>
            @endforeach
        </tbody>
    </table>

  </div>
</div>
@endif


<style>

  /* Table base */
  .google-style-table {
    width: 100%;
    border-collapse: collapse;
    font-size: 0.95rem;
  }

  /* Table header */
  .google-style-table thead tr {
    border-bottom: 1px solid #dadce0;
    background: #f8f9fa;
  }

  .google-style-table thead th {
    text-align: left;
    font-weight: 500;
    padding: 12px 12px 8px;
    color: #202124;
    user-select: none;
  }

  /* Table body rows */
  .google-style-table tbody tr {
    border-bottom: 1px solid #e8eaed;
    transition: background-color 0.15s ease-in-out;
  }

  /* Row hover */
  .google-style-table tbody tr:hover {
    background-color: #f1f3f4;
    cursor: default;
  }

  /* Table cells */
  .google-style-table tbody td {
    padding: 12px 12px 12px 8px;
    vertical-align: middle;
    color: #3c4043;
  }

  /* Subtle text for date */
  .google-style-table tbody td:last-child {
    color: #5f6368;
    font-size: 0.875rem;
  }

  /* Resume download link */
  .resume-link {
    color: #1a73e8;
    text-decoration: none;
    font-weight: 500;
    padding: 6px 12px;
    border-radius: 4px;
    transition: background-color 0.15s ease-in-out;
  }

  .resume-link:hover {
    background-color: #e8f0fe;
    text-decoration: underline;
  }

  /* Responsive: stack rows on small devices */
  @media (max-width: 640px) {
    .google-style-table,
    .google-style-table thead,
    .google-style-table tbody,
    .google-style-table th,
    .google-style-table td,
    .google-style-table tr {
      display: block;
    }

    .google-style-table thead tr {
      position: absolute;
      top: -9999px;
      left: -9999px;
    }

    .google-style-table tbody tr {
      margin-bottom: 1rem;
      border: 1px solid #dadce0;
      border-radius: 8px;
      padding: 12px;
      background: white;
    }

    .google-style-table tbody td {
      padding-left: 50%;
      text-align: left;
      position: relative;
      white-space: normal;
      word-wrap: break-word;
    }

    .google-style-table tbody td::before {
      position: absolute;
      top: 12px;
      left: 12px;
      width: 45%;
      padding-right: 10px;
      white-space: nowrap;
      font-weight: 600;
      color: #202124;
      content: attr(data-label);
    }
  }
</style>

<script>
  // Add data-label attributes for accessibility & responsive design
  document.addEventListener('DOMContentLoaded', () => {
    const headers = [...document.querySelectorAll('.google-style-table thead th')].map(th => th.textContent.trim());
    document.querySelectorAll('.google-style-table tbody tr').forEach(row => {
      row.querySelectorAll('td').forEach((td, i) => {
        td.setAttribute('data-label', headers[i]);
      });
    });
  });
</script>

@include('Admin.layouts.footer')