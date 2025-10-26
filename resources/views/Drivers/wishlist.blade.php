@include('layouts.header')

  <style>
    .wishlist-item {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 15px;
      background-color: #f8f9fa;
      border-radius: 8px;
      margin-bottom: 15px;
      border: 1px solid #ddd;
    }
    .wishlist-item img {
      width: 80px;
      height: 80px;
      object-fit: cover;
      border-radius: 5px;
    }
    .wishlist-item .details {
      flex-grow: 1;
      margin-left: 15px;
    }
    .wishlist-item .remove-btn {
      border: none;
      background: none;
      color: #e74c3c;
      font-size: 1.5rem;
      cursor: pointer;
    }
    .wishlist-actions {
      margin-top: 20px;
      display: flex;
      justify-content: space-between;
    }
  </style>

  <div class="page-wrapper">
    <div class="content container-fluid">
    <h3 class="mb-4">Your Truck Wishlist</h3>

    <!-- Wishlist Items -->
    <div class="wishlist-section">

      <!-- Example Wishlist Item 1 -->
      <div class="wishlist-item">
        <img src="https://img.freepik.com/premium-vector/trucking-company-logo-template_441059-260.jpg" alt="Ford F-150">
        <div class="details">
          <strong>Ford F-150</strong>
          <p><small>Price: $32,000</small></p>
          <p><small>Reliable and rugged, perfect for work and leisure.</small></p>
        </div>
        <button class="remove-btn" onclick="removeFromWishlist(this)"><i class="fas fa-trash"></i></button>
      </div>

      <!-- Example Wishlist Item 2 -->
      <div class="wishlist-item">
        <img src="https://img.freepik.com/premium-vector/trucking-company-logo-template_441059-260.jpg" alt="Chevrolet Silverado">
        <div class="details">
          <strong>Chevrolet Silverado</strong>
          <p><small>Price: $40,000</small></p>
          <p><small>Unmatched towing capacity and off-road capabilities.</small></p>
        </div>
        <button class="remove-btn" onclick="removeFromWishlist(this)"><i class="fas fa-trash"></i></button>
      </div>

      <!-- Example Wishlist Item 3 -->
      <div class="wishlist-item">
        <img src="https://img.freepik.com/premium-vector/trucking-company-logo-template_441059-260.jpg" alt="Ram 1500">
        <div class="details">
          <strong>Ram 1500</strong>
          <p><small>Price: $35,500</small></p>
          <p><small>Smooth ride with high-end luxury features.</small></p>
        </div>
        <button class="remove-btn" onclick="removeFromWishlist(this)"><i class="fas fa-trash"></i></button>
      </div>
    </div>

    <!-- Wishlist Summary -->
    <div class="wishlist-summary">
      <div class="wishlist-actions">
        <div class="total-price">
          <strong>Total Price:</strong> $107,500
        </div>
        <!--<div>
          <button class="btn btn-outline-primary">Add All to Cart</button>
        </div>-->
      </div>
    </div>
     </div>

    <!-- Actions -->
    <div class="wishlist-actions">
      <button class="btn btn-outline-secondary" onclick="clearWishlist()">Clear Wishlist</button>
    </div>
  </div>

  <script>
    function removeFromWishlist(button) {
      const wishlistItem = button.closest('.wishlist-item');
      wishlistItem.remove();
    }

    function clearWishlist() {
      const wishlistSection = document.querySelector('.wishlist-section');
      wishlistSection.innerHTML = '<p class="text-center">Your wishlist is empty.</p>';
    }
  </script>



@include('layouts.footer')