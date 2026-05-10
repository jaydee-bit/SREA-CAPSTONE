<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up()
    {
        Schema::create('incidents', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained();
            $table->string('type');
            $table->text('description');
            $table->string('photo_path')->nullable();
            $table->string('barangay');
            $table->string('location_details')->nullable();
            $table->decimal('latitude', 10, 7);
            $table->decimal('longitude', 10, 7);
            $table->text('address');
            $table->enum('status', ['Pending', 'Under Review', 'Resolved', 'Escalated', 'Rejected'])->default('Pending');
            $table->timestamp('reported_at')->useCurrent();
            $table->integer('persons_involved')->nullable();
            $table->foreignId('assigned_to')->nullable()->constrained('users');
            $table->text('responder_notes')->nullable();
            $table->text('escalation_reason')->nullable();
            $table->foreignId('escalated_by')->nullable()->constrained('users');
            $table->timestamp('escalated_at')->nullable();
            $table->text('resolution_notes')->nullable();
            $table->timestamp('resolved_at')->nullable();
            $table->timestamps();
        });
    }

    public function down()
    {
        Schema::dropIfExists('incidents');
    }
};