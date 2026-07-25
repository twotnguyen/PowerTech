using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PowerTech.Data;
using PowerTech.Constants;
using PowerTech.Models.Entities;

namespace PowerTech.Areas.Support.Controllers
{
    [Area("Support")]
    [Authorize(Roles = UserRoles.SupportStaff + "," + UserRoles.Admin)]
    public class ReviewController : Controller
    {
        private readonly ApplicationDbContext _context;

        public ReviewController(ApplicationDbContext context)
        {
            _context = context;
        }

        public async Task<IActionResult> Index(bool? approved, int? minRating, string q)
        {
            var query = _context.Reviews
                .Include(r => r.Product)
                .Include(r => r.User)
                .Include(r => r.ReviewImages)
                .OrderByDescending(r => r.CreatedAt)
                .AsQueryable();

            if (approved.HasValue)
            {
                query = query.Where(r => r.IsApproved == approved.Value);
            }

            if (minRating.HasValue)
            {
                query = query.Where(r => r.Rating >= minRating.Value);
            }

            if (!string.IsNullOrEmpty(q))
            {
                query = query.Where(r => 
                    (r.Product != null && r.Product.Name.Contains(q)) || 
                    (r.User != null && r.User.FullName != null && r.User.FullName.Contains(q)) ||
                    (r.Comment != null && r.Comment.Contains(q)));
                ViewBag.SearchTerm = q;
            }

            var reviews = await query.ToListAsync();
            ViewBag.Approved = approved;
            ViewBag.MinRating = minRating;

            return View(reviews);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Approve(int id)
        {
            var review = await _context.Reviews.FindAsync(id);
            if (review == null) return NotFound();

            review.IsApproved = true;
            review.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();
            TempData["SuccessMessage"] = "Đã phê duyệt đánh giá thành công!";
            
            return RedirectToAction(nameof(Index));
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Delete(int id)
        {
            var review = await _context.Reviews.FindAsync(id);
            if (review == null) return NotFound();

            _context.Reviews.Remove(review);
            await _context.SaveChangesAsync();
            
            TempData["SuccessMessage"] = "Đã xóa đánh giá thành công!";
            return RedirectToAction(nameof(Index));
        }
    }
}
