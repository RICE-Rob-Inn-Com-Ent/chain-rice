import asyncio
from contextlib import AsyncExitStack
from typing import Callable, Awaitable


async def with_retry(task: Callable[[], Awaitable[None]], *, retries: int = 3) -> None:
	for attempt in range(retries + 1):
		try:
			await task()
			return
		except Exception as exc:  # noqa: PIE786 - demo
			if attempt == retries:
				raise
			await asyncio.sleep(min(2 ** attempt, 5))


async def child(name: str, delay: float) -> None:
	try:
		await asyncio.sleep(delay)
		print(f"child {name} done")
	except asyncio.CancelledError:
		print(f"child {name} cancelled")
		raise


async def parent() -> None:
	async with AsyncExitStack() as stack:
		task_group = asyncio.TaskGroup()
		await stack.enter_async_context(task_group)

		for i in range(3):
			task_group.create_task(child(f"t{i}", delay=0.2 + i * 0.2))

		# Add a retried task that might fail intermittently
		async def flaky():
			await asyncio.sleep(0.1)
			raise RuntimeError("flaky error")

		task_group.create_task(with_retry(flaky, retries=2))

		# Timeout the whole group if it takes too long
		try:
			await asyncio.wait_for(task_group._tasks.pop().get_coro(), timeout=2)  # type: ignore[attr-defined]
		except asyncio.TimeoutError:
			print("parent timeout -> cancelling children")
			# TaskGroup will cancel children automatically on context exit


if __name__ == "__main__":
	asyncio.run(parent())