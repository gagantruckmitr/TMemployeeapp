<?php

// database/migrations/YYYY_MM_DD_create_subscriptions_table.php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateSubscriptionsTable extends Migration
{
    public function up()
    {
        Schema::create('subscriptions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->string('unique_id')->nullable();
            $table->string('order_id')->nullable();
            $table->unsignedBigInteger('start_at')->nullable();
            $table->unsignedBigInteger('end_at')->nullable();
            $table->decimal('amount', 10, 2)->nullable();
            $table->string('payment_id')->nullable();
            $table->string('payment_status')->nullable();
            $table->text('payment_details')->nullable();
            $table->timestamps();
        });
    }

    public function down()
    {
        Schema::dropIfExists('subscriptions');
    }
}

