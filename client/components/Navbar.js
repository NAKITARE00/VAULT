import Link from "next/link"
import {ConnectWallet} from "@thirdweb-dev/react"


export function Navbar() {
  return (
    <header key="1" className="flex h-20 w-full items-center px-4 md:px-6 bg-black text-white">
      <Link className="mr-6 flex items-center" href="#">
        <FileArchiveIcon className="h-6 w-6 text-white" />
        <span className="ml-2 text-lg font-semibold">IRONVAULT</span>
      </Link>
      <nav className="ml-auto flex gap-4 sm:gap-6 mr-[10px]">
        <Link className="text-sm font-medium hover:underline underline-offset-4" href="#">
          Home
        </Link>
        <Link className="text-sm font-medium hover:underline underline-offset-4" href="#">
          About
        </Link>
        <Link className="text-sm font-medium hover:underline underline-offset-4" href="#">
          Services
        </Link>
        <Link className="text-sm font-medium hover:underline underline-offset-4" href="#">
          Contact
        </Link>
      </nav>
      <ConnectWallet
        theme={"dark"}
        modalSize={"wide"}
      />
    </header>
  )
}

function FileArchiveIcon(props) {
  return (
    <svg
      {...props}
      xmlns="http://www.w3.org/2000/svg"
      width="24"
      height="24"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
    >
      <path d="M4 22V4c0-.5.2-1 .6-1.4C5 2.2 5.5 2 6 2h8.5L20 7.5V20c0 .5-.2 1-.6 1.4-.4.4-.9.6-1.4.6h-2" />
      <polyline points="14 2 14 8 20 8" />
      <circle cx="10" cy="20" r="2" />
      <path d="M10 7V6" />
      <path d="M10 12v-1" />
      <path d="M10 18v-2" />
    </svg>
  )
}
