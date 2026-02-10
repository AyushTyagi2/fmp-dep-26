using Microsoft.AspNetCore.Mvc;
using FmpBackend.Services;
using FmpBackend.Dtos;

namespace FmpBackend.Controllers;



[ApiController]
[Route("senders")]
public class SenderController : ControllerBase
{
    private readonly SenderService _service;

    public SenderController(SenderService service)
    {
        _service = service;
    }

    [HttpPost("onboard")]
    public IActionResult Onboard([FromBody] SenderOnboardingDto dto)
    {
        _service.OnboardSender(dto);
        return Ok(new { success = true });
    }
}
