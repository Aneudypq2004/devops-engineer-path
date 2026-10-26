using DevOpsLab.Api.Domain;
using Microsoft.EntityFrameworkCore;

namespace DevOpsLab.Api.Data;

public class AppDbContext(DbContextOptions<AppDbContext> options) : DbContext(options)
{
    public DbSet<TaskItem> Tasks => Set<TaskItem>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<TaskItem>(entity =>
        {
            entity.ToTable("tasks");
            entity.HasKey(t => t.Id);
            entity.Property(t => t.Id).HasColumnName("id");
            entity.Property(t => t.Title).HasColumnName("title").HasMaxLength(TaskItem.TitleMaxLength).IsRequired();
            entity.Property(t => t.IsDone).HasColumnName("is_done");
            entity.Property(t => t.CreatedAt).HasColumnName("created_at");
            entity.Property(t => t.UpdatedAt).HasColumnName("updated_at");
        });
    }
}
